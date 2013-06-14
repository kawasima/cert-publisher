namespace :cert_publisher do

  desc "start ldap server"
  task :ldap => :environment do
    Process.daemon
    class SQLOperation < LDAP::Server::Operation
      BASE_DN = "dc=cert-publisher"
      DN_ELEMENTS = {
        "UID"=> :uid,
        "CN" => :common_name,
        "OU" => :organization_unit_name,
        "O"  => :organization_name,
        "L"  => :locality_name,
        "ST" => :province_name,
        "C"  =>  :country_name
      }

      def search(basedn, scope, deref, filter)
        raise LDAP::ResultError::UnwillingToPerform, "Bad base DN" unless basedn == "ou=users,#{BASE_DN}"

        conds = case
                when filter[0] == :true
                  {}
                when filter.size == 4 && filter[0] == :eq && filter[1].class == String
                  if DN_ELEMENTS.include?(filter[1].upcase)
                    { DN_ELEMENTS[filter[1].upcase] => filter[3]}
                  elsif filter[1] == "mail"
                    { :email_address => filter[3] }
                  else
                    return
                  end
                else
                  raise LDAP::ResultError::UnwillingToPerform, "Bad filter: #{filter}"
                end

        users = User.all conds
        users.each do |user|
          attrs = { "mail" => user.email_address }
          DN_ELEMENTS.each_pair{ |dn, column_name|
            attrs[dn] = user.send column_name
          }
          send_SearchResultEntry("uid=#{user.uid},#{basedn}", attrs)
        end
      end

      def simple_bind(version, dn, password)
        return unless dn # anonumous
        unless dn =~ /^uid=([^,]+),ou=users,#{BASE_DN}$/
          raise LDAP::ResultError::UnwillingToPerform, "must end with ,ou=users,#{BASE_DN}."
        end

        uid = $1
        user = User.first(:uid => uid) or raise LDAP::ResultError::InvalidCredentials , "#{uid} is unknown."

        totp = ROTP::TOTP.new(user.otp_secret)
        unless totp.verify_with_drift(password, 120)
          raise LDAP::ResultError::InvalidCredentials, "Mismatch password in user #{mail}."
        end
      end
    end

    s = LDAP::Server.new(:port    => 1389,
                         :nodelay => true,
                         :listen  => 10,
                         :operation_class => SQLOperation)
    s.run_tcpserver
    stop_proc = Proc.new do
      puts "Stop LDAP server..."
      s.stop
      Process.kill
    end
    Signal.trap(:INT,  stop_proc)
    Signal.trap(:TERM, stop_proc)
    s.join
  end
end 
