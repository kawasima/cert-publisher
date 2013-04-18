class OperationLog
  include DataMapper::Resource

  property :id, Serial
  property :operated_at, DateTime, :required => true, :default => lambda{|p,s| DateTime.now}
  property :operated_on, Date, :default => lambda{|p,s| Date.today }
  property :user_name, String, :required => true
  property :url,  String, :length => 255, :required => true
  property :data, String, :length => 255
  property :user_id, Integer, :required => false  
end
