# -*- coding: utf-8 -*-

require 'data_mapper'
require 'models/user'
require 'sinatra/r18n'
require 'sinatra/flash'
require 'sinatra/reloader'

DataMapper.setup(:default, 'sqlite3:db.sqlite3')
DataMapper::Validations::I18n.localize! 'ja'
DataMapper::Pagination.defaults[:pager_class] = ""

class CertPublisherApp < Sinatra::Base
  register Sinatra::Flash
  register Sinatra::R18n
  register Sinatra::Reloader

  set :default_locale, 'en'
  set :translations, './i18n'
  set :haml, { :format => :html5 }
  set :sessions, true
  set :root, File.dirname(__FILE__)

  get '/' do
    page = params[:page] || 1
    @users = User.page page, :per_page => 2
    haml :index
  end

  get '/new_user' do
    @user = User.new
    haml :new_user
  end

  post '/new_user' do
  @user = User.new(params[:user])
    if @user.save
    flash[:notice] = t.message.updated
    redirect '/'
    else
      haml :new_user
    end
  end

  get '/destroy/:id' do
    @user = User.get(params[:id])
    if @user.destroy
      flash[:notice] = t.message.deleted
    else
      flash[:error] = t.message.failed_to_delete
    end
    redirect '/'
  end

  get '/extend/:id' do
  end

  get '/revoke/:id' do
  
  end
end

DataMapper.auto_upgrade!
