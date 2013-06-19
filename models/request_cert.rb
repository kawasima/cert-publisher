class RequestCert
  include DataMapper::Resource

  property :id, Serial  
  property :uid, String, :length => 50, :required => true, :format => /[A-Za-z0-9\.\+_]+/
  property :country_name, String, :required => true
  property :province_name, String, :required => true
  property :locality_name, String
  property :organization_name, String, :required => true
  property :organization_unit_name, String
  property :common_name, String, :required => true
  property :email_address, String, :required => true

  property :requested_at, DateTime, :default => lambda {|r,p| Time.now }

  validates_with_block :uid do
    if User.count(:uid => @uid) == 0
      true
    else
      [false, I18n.t("message.duplicated_uid")]
    end
  end
end
