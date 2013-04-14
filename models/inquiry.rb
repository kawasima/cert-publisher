class Inquiry
  include DataMapper::Resource

  property :id, Serial

  belongs_to :inquiry_by, 'User'
  property :description, Text
  property :inquiry_at, DateTime, :default => lambda{|r,p| Time.now}
end
