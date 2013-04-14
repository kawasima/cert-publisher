CertPublisher::App.controllers :admin_user do
  before do
    authenticate!
    unless @user.admin?
      halt 403
    end
  end

  get :index, :map => '/admin/user/' do
    page = params[:page] || 1
    @users = User.page page, :per_page => 10
    @request_certs = RequestCert.all(:limit => 10)
    render 'admin_user/list'
  end

  post :accept, :map => '/admin/user/accept/:request_cert_id' do
    session[:request_cert] = RequestCert.get(params[:request_cert_id])
    redirect url(:admin_user, :new)
  end

  get :new, :map => '/admin/user/new' do
    @user = User.new(settings.entry)
    if session[:request_cert]
      session[:request_cert].attributes.each_pair do |k,v|
        if @user.respond_to? "#{k.to_s}=" || !([:id, :admin].include? k)
          @user.attribute_set(k, v) 
        end
      end
    end
    render 'admin_user/new'
  end

  post :new, :map => '/admin/user/new' do
    @user = User.new(params[:user])
    generate_cert

    begin
      DataMapper::Transaction.new(@user, RequestCert).commit do
        @user.raise_on_save_failure = true 
        @user.save

        if session[:request_cert]
          session[:request_cert].raise_on_save_failure = true
          (session.delete :request_cert).destroy
        end
        flash[:notice] = t('message.updated')
        redirect url(:admin_user, :index)
      end
    rescue
      flash[:error] = t('message.failed_to_update')
      render 'admin_user/new'
    end
  end

  post :destroy, :map => '/admin/user/:id/destroy' do
    @user = User.get(params[:id])
    if @user.destroy
      flash[:notice] = t('message.deleted')
    else
      flash[:error] = t('message.failed_to_delete')
    end
    redirect url(:admin_user, :index)
  end

  post :extend, '/admin/user/:id/extend' do
    user = User.get(params[:id])
    old_cert = user.cert
    old_cert.active = false

    client_cert = X509::Certificate.new(old_cert.client_cert)
    new_cert = Cert.new(:expires => Time.now + 365 * 24 * 60 * 60,
                        :user => user)
    client_cert.not_after = new_cert.expires.to_time
    ca_key_pem = File.open(settings.ca[:key], "rb") {|f| f.read }
    ca_key = PKey::RSA.new(ca_key_pem, params[:ca_password])
    client_cert.sign(ca_key, "sha1")
    new_cert.client_cert = client_cert.to_pem

    puts "#{old_cert.inspect}///#{new_cert.inspect}"
    if old_cert.save && new_cert.save
      flash[:notice] = t('message.updated')
    else
      flash[:error] = t('message.failed_to_update')
    end
    redirect url(:admin_user, :index)
  end

  post :revoke, :map => '/admin/user/:id/revoke' do
    user = User.get(params[:id])

    revoked = X509::Revoked.new
    revoked.serial = user.cert.serial
    revoked.time = Time.now

    crl_pem = File.open(settings.crl[:key], "rb") {|f| f.read }
    crl = X509::CRL.new(crl_pem)
    crl.add_revoked(revoked)

    user.cert.active = false
    if user.cert.save
      flash[:notice] = t('message.updated')
    else
      flash[:error] = t('message.failed_to_update')
    end
    redirect url(:admin_user, :index)
  end

  post :sendmail, :map => '/admin/user/:id/sendmail' do
    @user = User.get(params[:id])
    email do
      from settings.site[:admin]["email_address"]
      to @user.email_address
      subject "[#{settings.site[:name]}] Your certification"
      body render('admin_user/cert_notify')
      via :sendmail   
    end
    flash[:notice] = t('message.sentmail')
    redirect url(:admin_user, :index)
  end
end
