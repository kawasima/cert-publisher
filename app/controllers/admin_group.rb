CertPublisher::App.controllers :admin_group do
  before do
    authenticate!
    unless @user.admin? or @user.members(:role => :manager).count > 0
      halt 403
    end
  end

  before :new do
    halt 403 unless @user.admin?
  end

  get :index, :map => '/admin/group/' do
    page = params[:page] || 1
    if @user.admin?
      @groups = Group.page page, :per_page => 10
    else
      @groups = Group.all(:members => [ :role => :manager,
            :user => { :id => @user.id } ])
    end
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
    conds = (@user.admin?) ? {} : { :members => [
        :role => :manager,
        :user => { :id => @user.id }
      ]}
    conds[:name] = params[:name]

    @group = Group.first(conds) or halt 403

    @users = User.all - @group.users
    render 'admin_group/show'
  end

  post :add_user, :map => '/admin/group/:name/add/:user_id' do
    member = Member.new(params[:member])
    member.user = User.get(params[:user_id])

    conds = (@user.admin?) ? {} : { :members => [
        :role => :manager,
        :user => { :id => @user.id }
      ]}
    conds[:name] = params[:name]
    member.group = Group.first(conds) or halt 403

    if member.save
      content_type "application/json"
      '{"result":"ok"}'
    else
      halt 500
    end
  end

  post :remove_user, :map => '/admin/group/:name/remove/:user_id' do
    conds = (@user.admin?) ? {} : { :members => [
        :role => :manager,
        :user => { :id => @user.id }
      ]}
    conds[:name] = params[:name]
    group = Group.first(conds) or halt 403

    user  = User.get(params[:user_id])
    group.users.delete(user)
    group.save
    content_type "application/json"
    user.attributes.to_json
  end
end
