class User
  include DataMapper::Resource

  property :id, Serial  
  property :uid, String, :length => 16, :required => true, :unique => true, :format => /[A-Za-z0-9\.\+_]+/

  # Required by SSL certificate
  property :country_name, String, :required => true
  property :province_name, String, :required => true
  property :locality_name, String
  property :organization_name, String, :required => true
  property :organization_unit_name, String
  property :common_name, String, :required => true
  property :email_address, String, :required => true, :format => :email_address, :unique => true

  property :admin, Boolean, :required => true, :default => false
  property :otp_secret, String, :default => lambda {|r,p| ROTP::Base32.random_base32 }

  property :dn, String, :length => 256, :required => true

  has n, :user_devices, :constraint => :destroy
  has n, :access_logs, :constraint => :set_nil
  has 1, :secret, :constraint => :destroy
  has 1, :account_lock, :constraint => :destroy
  belongs_to :cert, :parent_key => [ :serial ], :required => false

  has 1, :request_extension, :constraint => :destroy
  has n, :members
  has n, :groups, :through => :members
end
