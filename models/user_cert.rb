require 'data_mapper'

class UserCert
  include DataMapper::Resource

  property :id, Serial

  belongs_to :user
end
