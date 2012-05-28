require 'certificate'
require 'models/user'


describe Certificate do
  before do
    user = User.new
    user.country_name = 'JP'
    user.province_name = 'Tokyo'
    user.locality_name = 'Shinjuku-Ku'
    user.organization_name = 'TIS'
    user.organization_unit_name = 'NC1'
    user.common_name = 'www.tis.co.jp'
    user.email_address = 'kawasima1016@gmail.com'

    @cert = Certificate.new(user)
  end

  it "should create certificate" do
    pkey = @cert.generate_key("password")
    csr =  @cert.generate_csr(pkey)
    cert = @cert.generate_certificate("clientcertificate", csr)

    puts cert.to_pem
    pkcs12 = PKCS12.create("kawasima", "pagefoundry.dyndns.org", pkey, cert)
    puts pkcs12.to_der
  end
end

