class AccountLock
  include DataMapper::Resource

  property :id, Serial

  property :unlock_code, String, :required => true
  property :expires, DateTime
  property :reason, Enum[:transitional, :voluntary, :illegal], :required => true
  property :created_at, DateTime, :default => lambda{|r,p| Time.now }

  belongs_to :user, :required => true, :unique => true
end
