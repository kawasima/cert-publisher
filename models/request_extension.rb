class RequestExtension
  include DataMapper::Resource

  property :id, Serial
  belongs_to :user
  property :requested_at, DateTime, :default => lambda {|r,p| Time.now }
end  
