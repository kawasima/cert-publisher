class Cert
  include DataMapper::Resource

  property :serial, Integer, :key => true
  
  property :private_key, Text, :required => true
  property :client_cert, Text, :required => true
  property :expires, DateTime, :required => true
  property :token, String, :length => 20, :default => lambda { |r, p| rand(36**20).to_s(36) }
  property :active, Boolean, :required => true, :default => true

  belongs_to :user, :required => false
end
