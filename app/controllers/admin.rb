CertPublisher::App.controllers :admin do
  get :index, :map => '/admin/' do
    page = params[:page] || 1
    @users = User.page page, :per_page => 10
    render :index
  end

  get :new_user, :map => '/admin/new_user' do
    @user = User.new(settings.entry)
    haml :new_user
  end

  post '/admin/new_user' do
    @user = User.new(params[:user])
    cert = Certificate.new(@user)
    cert.ca_cert = settings.ca[:cert]
    cert.ca_key  = settings.ca[:key]
    pkey = cert.generate_key
    csr =  cert.generate_csr(pkey)
    cert = cert.generate_certificate(params[:ca_password], csr, User.max(:id) || 10)
    @user.expires = cert.not_after
    @user.private_key = pkey.to_pem
    @user.client_cert = cert.to_pem

    if system('htpasswd', '-b', settings.auth[:htpasswd], cert.subject.to_s, "password") and @user.save
      flash[:notice] = t.message.updated
      redirect to('/admin/')
    else
      flash[:error] = t.message.failed_to_update
      haml :new_user
    end
  end

  post '/admin/destroy/:id' do
    @user = User.get(params[:id])
    if @user.destroy
      flash[:notice] = t.message.deleted
    else
      flash[:error] = t.message.failed_to_delete
    end
    redirect to('/admin/')
  end

  post '/admin/extend/:id' do
    redirect to('/admin/')
  end

  post '/admin/revoke/:id' do
    redirect to('/admin/')
  end

  post '/admin/sendmail/:id' do
    @user = User.get(params[:id])
    Pony.mail(:to => @user.email_address,
              :from => settings.site[:admin]["email_address"],
              :subject => "[#{settings.site[:name]}] Your certification",
              :body => erb(:sendmail))
    flash[:notice] = t.message.sentmail
    redirect to('/admin/')
  end

  get '/admin/access_log' do
    page = params[:page] || 1
    @access_logs = AccessLog.page page, :per_page => 10, :order => [:session_started_at.desc]
    haml :access_log
  end
end
