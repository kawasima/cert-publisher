CertPublisher::App.controllers :admin_group do
  before do
    authenticate!
    unless @user.admin?
      halt 403
    end
  end

  get :index, :map => '/admin/group/' do
    page = params[:page] || 1
    @groups = Group.page page, :per_page => 10
    render 'admin_group/list'
  end

  get :new, :map => '/admin/group/new' do
    @group = Group.new
    render 'admin_group/new'
  end

  post :new, :map => '/admin/group/new' do
    @group = Group.new(params[:group])

    if @group.save
      flash[:notice] = t('message.updated')
      redirect url(:admin_group, :index)
    else
      flash[:error] = t('message.failed_to_update')
      render 'admin_group/new'
    end
  end

  get :show, :map => '/admin/group/:name' do
    @group = Group.first(:name => params[:name])
    @users = User.all - @group.users
    render 'admin_group/show'
  end

  post :add_user, :map => '/admin/group/:name/add/:user_id' do
    group = Group.first(:name => params[:name])
    user  = User.get(params[:user_id])
    group.users << user
    group.save!
    content_type "application/json"
    '{"result":"ok"}'
  end

  post :remove_user, :map => '/admin/group/:name/remove/:user_id' do
    group = Group.first(:name => params[:name])
    user  = User.get(params[:user_id])
    group.users.delete(user)
    group.save!
    content_type "application/json"
    '{"result":"ok"}'
  end
end
