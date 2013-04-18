CertPublisher::App.controllers :inquiry do
  before do
    authenticate!
  end

  before :index, :update do
    halt 403 unless @user.admin?
  end
  
  get :index, :map => "/user/inquiry/" do
    page = params[:page] || 1
    @inquiries = Inquiry.all(:processed => false).page page, :per_page => 10
    render 'inquiry/list'
  end

  get :new, :map => "/user/inquiry/new" do
    @inquiry = Inquiry.new
    render 'inquiry/new'
  end

  post :new, :map => "/user/inquiry/new" do
    @inquiry = Inquiry.new(params[:inquiry])
    @inquiry.inquiry_by = @user
    if @inquiry.save
      flash[:notice] = t('message.registered')
      redirect url(:user, :index)
    else
      flash[:error] = t('message.failed_to_update')
      render 'inquiry/new'
    end
  end

  get :show, :map => "/user/inquiry/:id" do
    @inquiry = Inquiry.get(params[:id])
    render 'inquiry/show'
  end

  get :update, :map => "/user/inquiry/:id/update" do
    @inquiry = Inquiry.get(params[:id])
    render 'inquiry/update'
  end

  post :update, :map => "/user/inquiry/:id/update" do
    @inquiry = Inquiry.get(params[:id])
    @inquiry.attributes = params[:inquiry]
    if @inquiry.save
      flash[:notice] = t('message.updated')
      redirect url(:inquiry, :index)
    else
      flash[:error] = t('message.failed_to_update')
      render 'inquiry/new'
    end
  end
end

