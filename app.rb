# -*- coding: utf-8 -*-

require 'data_mapper'
require 'sinatra/r18n'
require 'sinatra/flash'
require 'sinatra/config_file'
require 'sinatra/reloader'
require 'base64'
require 'openssl'
require 'pony'

require 'certificate'
require 'models/user'

require 'routes/user_routes'
require 'routes/admin_routes'

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

  use UserRoutes
  use AdminRoutes

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

  get '/' do
    ""
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

  error 401 do
    haml :not_found
  end

end
