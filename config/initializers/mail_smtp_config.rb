KEY_TO_PASSWD = Digest::SHA256.hexdigest("peregrineGuard Password")

newSettings = nil
if File.exist?(Rails.configuration.peregrine_configfile) then
   xmlfile = File.new(Rails.configuration.peregrine_configfile)
   configHash = Hash.from_xml(xmlfile)       
   if ( !configHash.nil? && !configHash['pgguard'].nil? && 
       	!configHash['pgguard']['email'].nil? && !configHash['pgguard']['email']['smtp'].nil?) then
      newSettings = configHash['pgguard']['email']['smtp']

      if !newSettings['password'].nil?
        decodePW = Base64.decode64(newSettings['password'])
        cipher = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
        cipher.decrypt
        cipher.key = KEY_TO_PASSWD
        passwd = cipher.update(decodePW)
        passwd << cipher.final
        newSettings['password'] = passwd
      end

      newSettings['to'] = configHash['pgguard']['email']['to']
      newSettings['cc'] = configHash['pgguard']['email']['cc']
   end
end # is there a PG config file?

if !newSettings.nil? then
  ActionMailer::Base.smtp_settings = {
    :address       => newSettings['ip'],
    :port          => newSettings['port'].to_i,
    :user_name     => newSettings['login'],
    :password      => newSettings['password'],
    :enable_starttls_auto => true
  }

  ActionMailer::Base.smtp_settings[:to] = newSettings['to'] if !newSettings['to'].blank?
  ActionMailer::Base.smtp_settings[:cc] = newSettings['cc'] if !newSettings['cc'].blank?

  if !newSettings['openSSLVerifyMode'].blank? then
     #
     # Reference: http://api.rubyonrails.org/classes/ActionMailer/Base.html
     #
     mode = newSettings['openssl_verify_mode']

     verifyModes = { 'none' => OpenSSL::SSL::VERIFY_NONE,
                     'peer' => OpenSSL::SSL::VERIFY_PEER,
                     'client_once' => OpenSSL::SSL::VERIFY_CLIENT_ONCE,
                     'fail_if_no_peer_cert' => OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
     }

     ActionMailer::Base.smtp_settings[:openssl_verify_mode] = verifyModes[mode] if verifyModes.hash_key?(mode)
  end

  if !newSettings['smtp_auth_type'].blank? then
     ActionMailer::Base.smtp_settings[:authentication] = newSettings['smtp_auth_type'].to_sym
  end

else # There is no email settings in the config file or config file is missing, then use defaults...
  # 
  # Defaults...
  #
  ActionMailer::Base.smtp_settings = {
    :address       => 'smtp.gmail.com',
    :port          => 587,
    :domain        => 'i7nw.com',
    :user_name     => 'i7mail@i7nw.com',
    :password      => '21ILuDiFtQEhmyhjZYGv2Q==',
    :authentication=> 'plain',
    :enable_starttls_auto => true,
    :to            => 'i7mail@i7nw.com'
  }

  #
  # Defaults used at QuickHeal POC
  #
  #
  #ActionMailer::Base.smtp_settings = {
  #  :address       => <user_ip_address>,
  #  :port          => <user_provided_port>,
  #  :user_name     => <user_name>,
  #  :password      => <user_password>,
  #  :openssl_verify_mode => OpenSSL::SSL::VERIFY_NONE,
  #  :enable_starttls_auto => true,
  #  :to            => <user_toAddr>
  #}

end

#
# This interceptor class will set the TO/CC and other fields (pulled from the XML config file) for every mail that is sent...
#
Mail.register_interceptor(PeregrineMailInterceptor)
