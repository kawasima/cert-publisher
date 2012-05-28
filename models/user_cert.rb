require 'data_mapper'

class UserCert
  include DataMapper::Resource

  property :id, Serial
  property :private_key, Text, :required => true
  property :client_cert, Text, :required => true
end
