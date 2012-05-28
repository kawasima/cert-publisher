require 'data_mapper'

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
end

