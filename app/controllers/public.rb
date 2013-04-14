CertPublisher::App.controllers :public do
  get :index, :map => '/' do
    render 'public/index'
  end

  get :login, :map => '/login' do
    auth ||=  Rack::Auth::Basic::Request.new(request.env)
    unless  auth.provided? && auth.basic? && auth.credentials
      response['WWW-Authenticate'] = %(Basic realm="CertPublisher for Development")
      throw(:halt, [401, "Not authorized\n"])
    end
    
    if /^emailAddress=(.*)$/ =~ auth.credentials[0] && User.count(:email_address => $1) > 0
      redirect url(:user, :index)
    else
      halt 401
    end
  end

  get :logout, :map => '/logout' do
    halt 401
  end
end
