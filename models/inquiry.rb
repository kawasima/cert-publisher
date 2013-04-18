class Inquiry
  include DataMapper::Resource

  property :id, Serial

  belongs_to :inquiry_by, 'User', :required => false
  property :description, Text
  property :inquiry_at, DateTime, :default => lambda{|r,p| Time.now}
  property :processed, Boolean, :default => false, :index => :unprocessed
end
