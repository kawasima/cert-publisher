# -*- coding: utf-8 -*-

require 'data_mapper'
require 'sinatra/r18n'
require 'sinatra/flash'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'base64'
require 'pony'

require 'certificate'
require 'models/user'


class CertPublisherApp < Sinatra::Base
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

  def initialize
    super
    DataMapper.setup(:default, settings.database_url)
    DataMapper::Validations::I18n.localize! 'ja'
    DataMapper::Pagination.defaults[:pager_class] = ""
    DataMapper.auto_upgrade!
  end

  before do
    request.script_name = '/cert-publisher'
  end

  before '/user/*' do
    @user = authenticate!(env)
    halt 401 unless @user
  end

  get '/' do
    ""
  end

  get '/admin/' do
    page = params[:page] || 1
    @users = User.page page, :per_page => 10
    haml :index
  end

  get '/admin/new_user' do
    @user = User.new(settings.entry)
    haml :new_user
  end

  post '/admin/new_user' do
    @user = User.new(params[:user])
    cert = Certificate.new(@user)
    cert.ca_cert = settings.ca[:cert]
    cert.ca_key  = settings.ca[:key]
    pkey = cert.generate_key
    csr =  cert.generate_csr(pkey)
    cert = cert.generate_certificate(params[:ca_password], csr, User.max(:id) || 10)
    @user.expires = cert.not_after
    @user.private_key = pkey.to_pem
    @user.client_cert = cert.to_pem

    if system('htpasswd', '-b', settings.auth[:htpasswd], cert.subject.to_s, "password") and @user.save
      flash[:notice] = t.message.updated
      redirect to('/admin/')
    else
      flash[:error] = t.message.failed_to_update
      haml :new_user
    end
  end

  post '/admin/destroy/:id' do
    @user = User.get(params[:id])
    if @user.destroy
      flash[:notice] = t.message.deleted
    else
      flash[:error] = t.message.failed_to_delete
    end
    redirect to('/admin/')
  end

  post '/admin/extend/:id' do
    redirect to('/admin/')
  end

  post '/admin/revoke/:id' do
    redirect to('/admin/')
  end

  post '/admin/sendmail/:id' do
    @user = User.get(params[:id])
    Pony.mail(:to => @user.email_address,
              :from => settings.site[:admin][:email_address],
              :subject => "[#{settings.site[:name]}] Your certification",
              :body => erb(:sendmail))
    flash[:notice] = t.message.sentmail
    redirect to('/admin/')
  end

  get '/show/:token' do
    @user = User.first(:token => params[:token])
    if @user
      haml :show
    else
      haml :not_found
    end
  end

  post '/download/ca' do
    ca_pem = File.open(settings.ca[:cert], "rb") {|f| f.read }
    ca_cert = X509::Certificate.new(ca_pem)
    content_type "application/x-x509-ca-cert"
    attachment "ca-cert.der"
    return ca_cert.to_der
  end

  post '/download/:token' do
    @user = User.first(:token => params[:token])

    cert = X509::Certificate.new(@user.client_cert)
    pkey = PKey::RSA.new(@user.private_key)
    ca_pem = File.open(settings.ca[:cert], "rb") {|f| f.read }
    ca_cert = X509::Certificate.new(ca_pem)

    pkcs12 = PKCS12.create(params[:pkcs12_password], @user.email_address, pkey, cert, [ca_cert])
    content_type "application/x-pkcs12"
    attachment "#{@user.email_address}-cert.p12"
    return pkcs12.to_der
  end

  get '/user/' do
    if request.cookies['device_token']
      haml :user
    elsif !@user.secret
      redirect to('/user/secret')
    else
      redirect to('/user/add_device')
    end
  end

  get '/user/secret' do
    @secret = Secret.new
    haml :user_secret
  end

  post '/user/secret' do
    @secret = Secret.new(params[:secret])
    @secret.user = @user
    if @secret.save
      flash[:notice] = t.message.updated
      redirect to('/user/')
    else
      flash[:error] = t.message.failed_to_update
      haml :user_secret
    end
  end

  get '/user/add_device' do
    @user_device = UserDevice.new
    haml :user_add_device
  end

  post '/user/add_device' do
    @user_device = UserDevice.new(params[:user_device])
    @user_device.user = @user
    @user_device.user_agent = request.user_agent

    if @user.secret.answer != params[:answer]
      flash[:error] = "秘密の質問の答えに誤りがあります"
      haml :user_add_device
    elsif @user_device.save
      response.set_cookie 'device_token', {
        :value => @user_device.token,
        :path => '/',
        :secure => request.secure?,
        :expire => Time.now + (3 * 365 * 24 * 60 * 60)
      }
      flash[:notice] = "登録しました"
      
      redirect to('/user/')
    else
      flash[:error] = t.message.failed_to_update
      haml :user_add_device
    end
  end

  error 401 do
    haml :not_found
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
end

