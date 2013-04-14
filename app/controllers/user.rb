CertPublisher::App.controllers :user do
  before :except => [:show, :download] do
    authenticate!
  end

  get :index, :map => '/user/' do
    if request.cookies['device_token']
      render 'user/index'
    elsif !@user.secret
      redirect url(:user, :secret)
    else
      redirect url(:user, :add_device)
    end
  end

  get :show_otp, :map => '/user/otp', :provides => :json do
    totp = ROTP::TOTP.new(@user.otp_secret)
    { :otp => totp.now }.to_json
  end

  get :show, :map => '/show/:token' do
    @user = User.first(:cert => { :token => params[:token] })
    if @user
      render 'user/show'
    else
      render 'user/not_found'
    end
  end

  post :download, :map => '/download/:token' do
    @user = User.first(:cert => { :token => params[:token] })

    cert = X509::Certificate.new(@user.cert.client_cert)
    pkey = PKey::RSA.new(@user.cert.private_key)
    ca_pem = File.open(settings.ca[:cert], "rb") {|f| f.read }
    ca_cert = X509::Certificate.new(ca_pem)

    pkcs12 = PKCS12.create(params[:pkcs12_password],
                           @user.email_address, pkey, cert, [ca_cert])
    content_type "application/x-pkcs12"
    attachment "#{@user.email_address}-cert.p12"
    pkcs12.to_der
  end

  get :secret, :map => '/user/secret' do
    @secret = @user.secret || Secret.new
    render 'user/secret'
  end

  post :secret, :map => '/user/secret' do
    @secret = @user.secret || Secret.new(:user => @user)
    @secret.attributes = params[:secret]

    if @secret.save
      flash[:notice] = t('message.updated')
      redirect url(:user, :index)
    else
      flash[:error] = t('message.failed_to_update')
      render 'user/secret'
    end
  end

  get :add_device, :map => '/user/add_device' do
    @user_device = UserDevice.new
    render 'user/add_device'
  end

  post :add_device, :map => '/user/add_device' do
    @user_device = UserDevice.new(params[:user_device])
    @user_device.user = @user
    @user_device.user_agent = request.user_agent

    if @user.secret.answer != params[:answer]
      flash[:error] = t('message.mismatch_secret')
      render 'user/add_device'
    elsif @user_device.save
      response.set_cookie 'device_token', {
        :value => @user_device.token,
        :path => '/',
        :secure => request.secure?,
        :expires => Time.now + (3 * 365 * 24 * 60 * 60)
      }
      flash[:notice] = t('message.registered')
      
      redirect url(:user, :index)
    else
      flash[:error] = t('message.failed_to_update')
      render 'user/add_device'
    end
  end

  post :remove_device, :map => '/user/remove_device/:id' do
    user_device = UserDevice.get(params[:id])
    
    if user_device.destroy
      flash[:notice] = t('message.deleted')
    else
      flash[:notice] = t('message.failed_to_delete')
    end
    redirect url(:user, :index)
  end

  get :start_session, :map => '/user/start_session' do
    @access_log = AccessLog.new
    @purposes = settings.purposes
    render 'user/start_session'
  end

  post :start_session, :map => '/user/start_session' do
    @access_log = AccessLog.new(params[:access_log])
    @access_log.user_name = @user.common_name
    @access_log.user_id   = @user.id
    device_token = request.cookies['device_token']
    user_device = UserDevice.first(:token => device_token)
    redirect url(:user, :add_device) unless user_device
    @access_log.device_name = user_device.name

    if @access_log.save
      device_session = generate_device_session(device_token)
      response.set_cookie("device_session",
                          :value => device_session,
                          :path => "/",
                          :secure => request.secure?
                          )
      redirect url(:user, :index, :back_url => params[:back_url])
    else
      flash[:error] = t('message.failed_to_update')
      render 'user/start_session'
    end
  end

  define_method :generate_device_session do |device_token|
    expires = Time.now.to_i + 24 * 60 * 60
    hmac = OpenSSL::HMAC.new(settings.auth[:key], OpenSSL::Digest::SHA1.new)
    hmac.update("#{expires}#{device_token}")
    "#{expires}$#{Base64.encode64(hmac.digest).gsub(/(\r|\n)/,'')}"
  end  
end
