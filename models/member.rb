class Member
  include DataMapper::Resource

  belongs_to :user, :key => true
  belongs_to :group, :key => true

  property :role, Enum[:manager, :developer], :required => true, :default => :developer
end
