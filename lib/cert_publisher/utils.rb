module CertPublisher
  module Utils
    class << self
      def registered app
        app.controller do
          define_method :authenticate! do
            if User.count == 1
              @user = User.first
            end

            if env.include? 'HTTP_AUTHORIZATION'
              dn,password = Base64.decode64(env['HTTP_AUTHORIZATION'][5..-1]).split(":")
              dn.split("/").each do |token|
                name, value = token.split("=")
                if name == "emailAddress"
                  @user = User.first(:email_address => value)
                end
              end
            end
            
            halt 401 unless @user
          end

          define_method :generate_cert do
            pkey = PKey::RSA.generate(CertificateBuilder::KEY_SIZE)
            x509_cert = CertificateBuilder.new(@user)
              .ca(:cert => settings.ca[:cert],
              :key => settings.ca[:key],
              :password => params[:ca_password])
              .serial(CertSerial.nextval)
              .private_key(pkey)
              .build
            @user.dn = "/C=#{@user.country_name}/ST=#{@user.province_name}/L=#{@user.locality_name}" <<
      "/O=#{@user.organization_name}/OU=#{@user.organization_unit_name}" <<
      "/CN=#{@user.common_name}/emailAddress=#{@user.email_address}"

            @user.cert = Cert.new(
              :serial => x509_cert.serial,
              :expires => x509_cert.not_after,
              :private_key => pkey.to_pem,
              :client_cert => x509_cert.to_pem)
          end
        end
      end
    end
  end
end
