require 'data_mapper'

require 'models/user_device'
require 'models/secret'

class User
  include DataMapper::Resource

  property :id, Serial

  property :country_name, String, :required => true
  property :province_name, String, :required => true
  property :locality_name, String
  property :organization_name, String, :required => true
  property :organization_unit_name, String
  property :common_name, String, :required => true
  property :email_address, String, :required => true

  property :private_key, Text, :required => true
  property :client_cert, Text, :required => true
  property :expires, DateTime, :required => true
  property :token, String, :length => 20, :default => lambda { |r, p| rand(36**20).to_s(36) }

  has n, :user_devices
  has n, :access_logs
  has 1, :secret
end

