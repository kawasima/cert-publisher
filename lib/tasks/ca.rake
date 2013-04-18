# encoding: utf-8

require 'highline'
require 'openssl'
require 'sinatra'
require 'sinatra/config_file'

include OpenSSL


namespace :cert_publisher do
  namespace :ca do
    desc "Generate CA"
    task :generate do 
      HighLine.track_eof = false
      config_file 'config/settings.yml'
      ui = HighLine.new

      cakey = PKey::RSA.generate(2048)
      passphrase = ui.ask("Enter pass phrase.") {|q| q.echo = false}
      File.open(settings.ca["key"], "w") do |f|
        f.write(cakey.export(Cipher::Cipher.new("aes256"), passphrase))
      end
    
      subject = X509::Name.new
      subject.add_entry("C", ui.ask("Country? ") {|q|
          q.default = settings.entry["country_name"]})
      subject.add_entry("ST", ui.ask("Province? ") {|q|
                        q.default = settings.entry["province_name"] })
      subject.add_entry("L", ui.ask("Locality? ") {|q|
                        q.default = settings.entry["locality_name"] })
      subject.add_entry("O", ui.ask("Organization? ") {|q|
          q.default = settings.entry["organization_name"] })
      subject.add_entry("OU", ui.ask("Organization Unit? ") {|q|
          q.default = settings.entry["organization_unit_name"] })
      subject.add_entry("CN", ui.ask("Common name? "))
      cacert = X509::Certificate.new
      cacert.serial = 0
      cacert.version = 0
      cacert.not_before = Time.now
      cacert.not_after = Time.now + 365 * 24 * 60 * 60
      cacert.subject = subject
      cacert.issuer = subject
      cacert.public_key = cakey.public_key

      ef = X509::ExtensionFactory.new
      ef.subject_certificate = cacert
      ef.issuer_certificate = cacert
      cacert.add_extension(ef.create_extension("basicConstraints", "CA:TRUE", false))
      cacert.add_extension(ef.create_extension("authorityKeyIdentifier", "keyid,issuer"))
      cacert.add_extension(ef.create_extension("subjectKeyIdentifier", "hash", false))

      cacert.sign(cakey, "sha1")

      File.open(settings.ca["cert"], "w") {|f| f.puts cacert.to_pem }
    end
  end
end
