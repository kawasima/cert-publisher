class Secret
  include DataMapper::Resource

  belongs_to :user, :key => true

  property :question, String, :required => true
  property :answer,   String, :required => true
end
