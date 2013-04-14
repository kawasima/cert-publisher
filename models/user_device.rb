class UserDevice
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :serial, String, :required => true
  property :token, String, :length => 20, :default => lambda { |r, p| rand(36**20).to_s(36) }
  property :user_agent, String, :length => 255, :required => true

  belongs_to :user
end
