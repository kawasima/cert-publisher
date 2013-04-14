CertPublisher::App.controllers :admin_audit do
  before do
    authenticate!
    unless @user.admin?
      halt 403
    end
  end

  get :access_log, :map => '/admin/audit/access_log' do
    page = params[:page] || 1
    @access_logs = AccessLog.page page, :per_page => 30, :order => [:session_started_at.desc]
    render 'admin_audit/access_log'
  end
end
