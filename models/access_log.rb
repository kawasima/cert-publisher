class AccessLog
  include DataMapper::Resource

  property :id, Serial
  property :session_started_at, DateTime, :required => true, :default => lambda{|p,s| DateTime.now}
  property :session_started_on, Date, :default => lambda{|p,s| Date.today}
  property :user_name, String, :required => true
  property :device_name, String, :required => true
  property :purpose, String, :required => true, :length => 255
  property :user_id, Integer, :required => false
end
