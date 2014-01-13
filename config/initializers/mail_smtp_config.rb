KEY_TO_PASSWD = Digest::SHA256.hexdigest("peregrineGuard Password")

newSettings = nil
if File.exist?(Rails.configuration.peregrine_configfile) then
   xmlfile = File.new(Rails.configuration.peregrine_configfile)
   configHash = Hash.from_xml(xmlfile)       
   if ( !configHash.nil? && !configHash['pgguard'].nil? && 
       	!configHash['pgguard']['email'].nil? && !configHash['pgguard']['email']['smtp'].nil?) then
      newSettings = configHash['pgguard']['email']['smtp']

      decodePW = Base64.decode64(newSettings['password'])
      cipher = OpenSSL::Cipher::Cipher.new("AES-256-CBC")
      cipher.decrypt
      cipher.key = KEY_TO_PASSWD
      passwd = cipher.update(decodePW)
      passwd << cipher.final
      newSettings['password'] = passwd

      newSettings['to'] = configHash['pgguard']['email']['to']
      newSettings['cc'] = configHash['pgguard']['email']['cc']
   end
end # is there a PG config file?

if !newSettings.nil? then
  ActionMailer::Base.smtp_settings = {
    :address       => newSettings['ip'],
    :port          => newSettings['port'].to_i,
    :domain        => 'i7nw.com',
    :user_name     => newSettings['login'],
    :password      => newSettings['password'],
    :authentication=> 'plain',
    :enable_starttls_auto => true,
    :to            => newSettings['to']
  }
else
  # 
  # Defaults...
  #
  ActionMailer::Base.smtp_settings = {
    :address       => 'smtp.gmail.com',
    :port          => 587,
    :domain        => 'i7nw.com',
    :user_name     => 'i7mail@i7nw.com',
    :password      => 'm@ilfr0mi7',
    :authentication=> 'plain',
    :enable_starttls_auto => true,
    :to            => 'i7mail@i7nw.com'
  }
end