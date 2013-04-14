CertPublisher::App.controllers :account_lock do
  before :create do
    authenticate!
  end

  define_method :unlock do
    begin
      account_lock = AccountLock.first(:unlock_code => params[:unlock_code])
      account_lock.raise_on_save_failure = true
      account_lock.destroy
      redirect url(:user, :index)
    rescue
      flash[:error] = t('message.fail_to_unlock')
      rener 'account_lock/destroy'
    end
  end

  post :create, :map => '/user/lock' do
    @user.account_lock = AccountLock.new(
      :unlock_code => SecureRandom.hex(16),
      :reason => :voluntary
    )
    begin
      DataMapper::Transaction.new(@user).commit do
        @user.save
        email(
          :from => settings.site[:admin][:email_address],
          :to => @user.email_address,
          :subject => "Lock your account [#{settings.site[:name]}]",
          :body => render('account_lock/lock_notify'),
          :via => :sendmail)
      end
      redirect url(:public, :index)
    end
  end

  get :destroy, :map => '/unlock' do
    if params[:unlock_code]
      unlock
    else
      render 'account_lock/destroy'
    end
  end

  post :destroy, :map => '/unlock' do
    unlock
  end
end
