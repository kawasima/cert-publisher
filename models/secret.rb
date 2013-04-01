require 'data_mapper'

require_relative 'user'

class Secret
  include DataMapper::Resource

  property :id, Serial
  property :question, String, :required => true
  property :answer,   String, :required => true

  belongs_to :user
end
