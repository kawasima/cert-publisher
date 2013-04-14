module CertPublisher
  class App < Padrino::Application
    register SassInitializer
    register Padrino::Rendering
    register Padrino::Mailer
    register Padrino::Helpers
    register CertPublisher::Utils

    enable :sessions

    def parse_http(str)
      return [] if str.nil?
      locales = str.split(',')
      locales.map! do |locale|
        locale = locale.split ';q='
        if 1 == locale.size
          [locale[0], 1.0]
        else
          [locale[0], locale[1].to_f]
        end
      end
      locales.sort! { |a, b| b[1] <=> a[1] }
      locales.map! { |i| i[0] }
    end

    before do
      locales = parse_http(request.env['HTTP_ACCEPT_LANGUAGE'])
      I18n.locale = locales[0] unless locales.empty?
    end

    ##
    # Caching support
    #
    # register Padrino::Cache
    # enable :caching
    #
    # You can customize caching store engines:
    #
    # set :cache, Padrino::Cache::Store::Memcache.new(::Memcached.new('127.0.0.1:11211', :exception_retry_limit => 1))
    # set :cache, Padrino::Cache::Store::Memcache.new(::Dalli::Client.new('127.0.0.1:11211', :exception_retry_limit => 1))
    # set :cache, Padrino::Cache::Store::Redis.new(::Redis.new(:host => '127.0.0.1', :port => 6379, :db => 0))
    # set :cache, Padrino::Cache::Store::Memory.new(50)
    # set :cache, Padrino::Cache::Store::File.new(Padrino.root('tmp', app_name.to_s, 'cache')) # default choice
    #

    ##
    # Application configuration options
    #
    # set :raise_errors, true       # Raise exceptions (will stop application) (default for test)
    # set :dump_errors, true        # Exception backtraces are written to STDERR (default for production/development)
    # set :show_exceptions, true    # Shows a stack trace in browser (default for development)
    # set :logging, true            # Logging in STDOUT for development and file for production (default only for development)
    # set :public_folder, 'foo/bar' # Location for static assets (default root/public)
    # set :reload, false            # Reload application files (default in development)
    # set :default_builder, 'foo'   # Set a custom form builder (default 'StandardFormBuilder')
    # set :locale_path, 'bar'       # Set path for I18n translations (default your_app/locales)
    # disable :sessions             # Disabled sessions by default (enable if needed)
    # disable :flash                # Disables sinatra-flash (enabled by default if Sinatra::Flash is defined)
    # layout  :my_layout            # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
    #

    ##
    # You can configure for a specified environment like:
    #
    #   configure :development do
    #     set :foo, :bar
    #     disable :asset_stamp # no asset timestamping for dev
    #   end
    config_file = Padrino.root("config", "settings.yml")
    if File.exists? config_file
      document = IO.read(config_file)
      yaml = HashWithIndifferentAccess.new(YAML.load(document) || {})
      yaml.each_pair do |key, value|
        set key, value
      end
    end

    ##
    # You can manage errors like:
    #
    error 404 do
      render 'errors/404'
    end

    error 401 do
      render 'errors/401'
    end
  end
end
