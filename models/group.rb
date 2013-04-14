class Group
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :description, String

  has n, :members
  has n, :users, :through => :members
end
