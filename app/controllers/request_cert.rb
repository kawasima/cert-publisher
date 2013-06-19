CertPublisher::App.controllers :request_cert do
  get :new, :map => '/request_cert/new' do
    @request_cert = RequestCert.new(settings.entry)
    render 'request_cert/new'
  end

  post :new, :map => '/request_cert/new' do
    if User.count == 0
      session[:request_cert] = User.new(params[:user])
      render 'request_cert/beginning'
    else
      @request_cert = RequestCert.new(params[:user])
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
    if User.count == 0
      @user = session.delete :request_cert
      @user.admin = true
      generate_cert
      if @user.save
        redirect url(:admin_user, :index)
      else
        flash[:error] = t('message.failed_to_update')
        redirect url(:request_cert, :new)
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
