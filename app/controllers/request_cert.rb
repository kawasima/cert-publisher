CertPublisher::App.controllers :request_cert do
  get :new, :map => '/request_cert/new' do
    @request_cert = RequestCert.new
    render 'request_cert/new'
  end

  post :new, :map => '/request_cert/new' do
    if User.all.empty?
      session[:user] = params[:request_cert]
      render 'request_cert/beginning'
    else
      @request_cert = RequestCert.new(params[:request_cert])
      if @request_cert.save
        flash[:notice] = t('message.accepted_request')
        redirect url(:public, :index)
      else
        flash[:error] = t('message.failed_to_update')
        render 'request_cert/new'
      end
    end
  end

  post :beginning, :map => 'request_cert/beginning' do
    if User.all.empty?
      @user = User.new(session[:user])
      @user.admin = true
      generate_cert
      if @user.save
        redirect url(:admin_user, :index)
      else
        render 'request_cert/beginning'
      end
    else
      halt 403
    end
  end

  get :destroy, :map => 'request_cert/destroy/:id' do
    if RequestCert.destroy(id)
      render 'request_cert/destroy'
    else
      flash[:notice] = t('message.fail_to_update')
      redirect url(:admin_user, :index)
    end
  end
end
