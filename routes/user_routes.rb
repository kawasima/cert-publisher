# -*- coding: utf-8 -*-

require 'sinatra/base'

class UserRoutes < Sinatra::Base
  register Sinatra::Flash
  register Sinatra::R18n
  register Sinatra::Reloader
  register Sinatra::ConfigFile

  config_file 'config/defaults.yml'

  set :default_locale, 'en'
  set :translations, './i18n'
  set :haml, { :format => :html5 }
  set :sessions, true
  set :root, File.dirname(__FILE__)
  set :views, 'views/user'

  before do
    request.script_name = '/cert-publisher'
  end

  before '/user/*' do
    @user = authenticate!(env)
    halt 401 unless @user
  end

  get '/user/' do
    if request.cookies['device_token']
      haml :index
    elsif !@user.secret
      redirect to('/user/secret')
    else
      redirect to('/user/add_device')
    end
  end

  get '/user/secret' do
    redirect to('/user/secret/update') if @user.secret
    @secret = Secret.new
    haml :secret
  end

  post '/user/secret' do
    @secret = @user.secret or Secret.new(:user => @user)
    @secret.attributes = params[:secret]

    if @secret.save
      flash[:notice] = t.message.updated
      redirect to('/user/')
    else
      flash[:error] = t.message.failed_to_update
      haml :secret
    end
  end

  get '/user/secret/update' do
    @secret = @user.secret
    haml :secret
  end

  get '/user/add_device' do
    @user_device = UserDevice.new
    haml :add_device
  end

  post '/user/add_device' do
    @user_device = UserDevice.new(params[:user_device])
    @user_device.user = @user
    @user_device.user_agent = request.user_agent

    if @user.secret.answer != params[:answer]
      flash[:error] = t.message.mismatch_secret
      haml :add_device
    elsif @user_device.save
      response.set_cookie 'device_token', {
        :value => @user_device.token,
        :path => '/',
        :secure => request.secure?,
        :expires => Time.now + (3 * 365 * 24 * 60 * 60)
      }
      flash[:notice] = t.message.registered
      
      redirect to('/user/')
    else
      flash[:error] = t.message.failed_to_update
      haml :add_device
    end
  end

  post '/user/remove_device/:id' do
    user_device = UserDevice.get(params[:id])
    
    if user_device.destroy
      flash[:notice] = t.message.deleted
    else
      flash[:notice] = t.message.failed_to_delete
    end
    redirect to('/user/')
  end

  get '/user/start_session' do
    @access_log = AccessLog.new
    @purposes = settings.purposes
    haml :start_session
  end

  post '/user/start_session' do
    @access_log = AccessLog.new(params[:access_log])
    @access_log.user = @user
    @access_log.user_name = @user.common_name
    device_token = request.cookies['device_token']
    user_device = UserDevice.first(:token => device_token)
    redirect to('/user/add_device') unless user_device
    @access_log.device_name = user_device.name

    if @access_log.save
      device_session = generate_device_session(device_token)
      response.set_cookie("device_session",
                          :value => device_session,
                          :path => "/",
                          :secure => request.secure?
                          )
      url = '/user/'
      url << "?back_url=#{URI.escape(params[:back_url])}"
      redirect to(url)
    else
      flash[:error] = t.message.failed_to_update
      haml :start_session
    end
  end

  private
  def authenticate!(env)
    user = nil
    if env.include? 'HTTP_AUTHORIZATION'
      dn,password = Base64.decode64(env['HTTP_AUTHORIZATION'][5..-1]).split(":")
      dn.split("/").each do |token|
        name, value = token.split("=")
        if name == "emailAddress"
          user = User.first(:email_address => value)
        end
      end
    end
    user
  end

  def generate_device_session(device_token)
    expires = Time.now.to_i + 24 * 60 * 60
    hmac = OpenSSL::HMAC.new(settings.auth[:key], OpenSSL::Digest::SHA1.new)
    hmac.update("#{expires}#{device_token}")
    "#{expires}$#{Base64.encode64(hmac.digest).gsub(/(\r|\n)/,'')}"
  end
end
