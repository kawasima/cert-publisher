CertPublisher::App.controllers :admin_audit do
  before do
    authenticate!
    unless @user.admin?
      halt 403
    end
  end

  get :access_log, :map => '/admin/audit/access_log', :provides => [:html, :js] do
    page = params[:page] || 1
    conds = {}
    if params[:session_started_from]
      conds[:session_started_at.gte] = DateTime.parse(params[:session_started_from])
    end
    if params[:session_started_to]
      conds[:session_started_at.lte] = DateTime.parse(params[:session_started_to])
    end
    @access_logs = AccessLog.all(conds).page page, :per_page => 30, :order => [:session_started_at.desc]

    case content_type
    when :html
      render 'admin_audit/access_log'
    when :js
      "$('table.access-logs').html('#{js_escape_html partial("admin_audit/access_log_table")}');"
    end
  end

  get :operation_log, :map => '/admin/audit/operation_log' do
    page = params[:page] || 1
    @operation_logs = OperationLog.page page, :per_page => 30, :order => [:operationed_at.desc]
    render 'admin_audit/operation_log'
  end

  get :access_activity, :map => "/admin/audit/access_activity", :provides => [:json] do
    content_type "application/json"
    access_counts = AccessLog.aggregate(:session_started_on, :all.count)
    (Date.today-365..Date.today).map do |day|
      [day, (access_counts.find{|el| el[0] == day } || [0, 0])[1]]
    end.to_json
  end
end
