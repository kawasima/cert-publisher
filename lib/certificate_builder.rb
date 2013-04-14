require 'openssl'
include OpenSSL

class CertificateBuilder
  KEY_SIZE = 2048
  
  def initialize(entry)
    @entry = entry
    @expires = 365
    @ca = {
      :cert => "/etc/ssl/certs/ssl-cert-snakeoil.pem",
      :key  => "/etc/ssl/private/ssl-cert-snakeoil.key",
      :password => nil,
    }
  end

  def build
    generate_key unless @pkey
    csr = generate_csr
    generate_certificate(csr)
  end

  def private_key(pkey)
    @pkey = pkey
    self
  end

  def ca(ca)
    @ca.merge!(ca)
    self
  end

  def serial(serial)
    @serial = serial
    self
  end

  private
  def generate_key
    @pkey = PKey::RSA.generate(KEY_SIZE)
  end

  def generate_csr
    csr = X509::Request.new
    name = X509::Name.new
    name.add_entry('C',  @entry.country_name)
    name.add_entry('ST', @entry.province_name)
    name.add_entry('L',  @entry.locality_name)
    name.add_entry('O',  @entry.organization_name)
    name.add_entry('OU', @entry.organization_unit_name)
    name.add_entry('CN', @entry.common_name)
    name.add_entry('emailAddress', @entry.email_address)

    csr.subject = name
    csr.version = 0
    csr.public_key = @pkey

    csr.sign(@pkey, "sha1")
    csr
  end

  def generate_certificate(csr)
    cert = X509::Certificate.new
    
    ca_pem = File.open(@ca[:cert], "rb") {|f| f.read }
    ca_cert = X509::Certificate.new(ca_pem)

    cert.version = ca_cert.version
    cert.issuer  = ca_cert.subject
    cert.subject = csr.subject
    cert.serial = @serial
    now = Time.now
    cert.not_before = now
    cert.not_after = Time.at(now.to_i + @expires * 24* 60 * 60)
    cert.public_key = csr.public_key

    ef = X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = ca_cert
    cert.add_extension(ef.create_extension("basicConstraints", "CA:FALSE", false))
    cert.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid:always"))
    cert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))

    ca_secret_key = File.open(@ca[:key], "rb") {|f| f.read }
    cert.sign(PKey::RSA.new(ca_secret_key, @ca[:password]), "sha1")
    cert
  end
end

