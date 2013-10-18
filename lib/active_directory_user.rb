# ActiveDirectoryUser (active_directory_user.rb)
# Author       : Ernie Miller
# Last modified: 4/4/2008
#
# Description:
#   A class for authenticating via Active Directory and providing
#   more developer-friendly access to key user attributes through configurable
#   attribute readers.
# 
#   You might find this useful if you want to use a central user/pass from AD
#   but still keep a local DB cache of certain user details for use in foreign
#   key constraints, for instance.
#
# Configuration:
#   Set your server information below, then add attributes you are interested
#   in to the ATTR_SV or ATTR_MV hashes, depending on whether they are single
#   or multi-value attributes. The left hand side is your desired name for
#   the attribute, and the right hand side is the attribute name as it exists
#   in the directory.
#
#   An optional Proc can be supplied to perform some processing on the raw
#   directory data before returning it. This proc should accept a single
#   parameter, the value to be processed. It will be used in Array#collect
#   for multi-value attributes.
#
#   Example:
#     :flanderized_first_name => [ :givenname,
#                                  Proc.new {|n| n + '-diddly'} ]
#
# Usage:
#   user = ActiveDirectoryUser.authenticate('emiller','password')
#   user.first_name # => "Ernie"
#   user.flanderized_first_name # => "Ernie-diddly"
#   user.groups     # => ["Mac Users", "Geeks", "Ruby Coders", ... ]

require 'net/ldap' # gem install ruby-net-ldap

class ActiveDirectoryUser

  KEY_TO_LOGIN = Digest::SHA256.hexdigest("peregrineGuard User")
  KEY_TO_PASSWD = Digest::SHA256.hexdigest("peregrineGuard Password")

  ### BEGIN CONFIGURATION ###
  # ATTR_SV is for single valued attributes only. Generated readers will
  # convert the value to a string before returning or calling your Proc.
  ATTR_SV = {
              :username => :samaccountname,
              #:first_name => :givenname,
              #:last_name => :sn,
              :email => :mail
            }
            

  # ATTR_MV is for multi-valued attributes. Generated readers will always 
  # return an array.
  ATTR_MV = {
              :groups => [ :memberof,
                           # Get the simplified name of first-level groups.
                           # TODO: Handle escaped special characters
                           Proc.new {|g| g.sub(/.*?CN=(.*?),.*/, '\1')} ]
            }

  # Exposing the raw Net::LDAP::Entry is probably overkill, but could be set
  # up by uncommenting the line below if you disagree.
  #attr_reader :entry

  ### END CONFIGURATION ###

  # Automatically fail login if login or password are empty. Otherwise, try
  # to initialize a Net::LDAP object and call its bind method. If successful,
  # we find the LDAP entry for the user and initialize with it. Returns nil
  # on failure.

  def self.ldapConnect(login, pass) 
    @config = YAML.load_file("/usr/local/etc/pgguard/ldap.yml")

    return nil if login.empty? or pass.empty? or (@config.nil? or @config["server"].nil?)

    conn = Net::LDAP.new :host => @config['server'],
                         :port => @config['port'],
                         #:encryption => :simple_tls,
                         :base => @config['base'],
                         :auth => { :username => "#{login}@#{@config['domain']}",
                                    :password => pass,
                                    :method => :simple }
    return conn
  end

  def self.authenticate(login, pass)
    
    conn = ldapConnect(login, pass)

    if conn.nil?
       return nil
    end

    #
    # Get only the LDAP attributes that we want and not the entire LDAP record
    #
    attrs = Array.new
    ATTR_SV.each { |k,v| attrs << v.to_s }
    ATTR_MV.each do |k,v| 
      if v.kind_of?(Array) 
        attrs << v.first.to_s 
      else
        attrs << v.to_s
      end
    end

    if conn.bind and entry = conn.search(:filter => "sAMAccountName=#{login}", :attributes => attrs).first
       user = self.new(entry)
       user.loginName = Encryptor.encrypt(login, :key => KEY_TO_LOGIN)
       user.passwd = Encryptor.encrypt(pass, :key => KEY_TO_PASSWD)
       return user
    else
      return nil
    end
  # If we don't rescue this, Net::LDAP is decidedly ungraceful about failing
  # to connect to the server. We'd prefer to say authentication failed.
  rescue Net::LDAP::LdapError => e
    return nil
  end

 def member_of?(group)
    return self.groups.include?(group)
  end

  def name
    return self.username
  end

  def admin?
    self.member_of?("Administrators")
  end
  
  def loginName=(login)
      @loginName = login
  end

  def passwd=(password)
      @passwd = password
  end
  #
  # Get all the users (and the groups they belong to) within the given domain.
  # This call reuses the LDAP connection made during authentication() call.
  #
  def listUsers

      listOfUsers = Array.new

      conn = ActiveDirectoryUser.ldapConnect(Encryptor.decrypt(@loginName, :key => KEY_TO_LOGIN),
                         Encryptor.decrypt(@passwd, :key => KEY_TO_PASSWD))
      if conn and conn.bind 

         config = YAML.load_file("/usr/local/etc/pgguard/ldap.yml")

         filter = Net::LDAP::Filter.eq("objectCategory", "organizationalPerson")
         conn.search(:base => config['base'], :filter => filter) do |entry|
             if !entry['samaccountname'].first.nil?
                if entry.attribute_names.include?(:memberof)
                   groups = []
                   entry.memberof.each do |g|
                      groups << g.gsub(/.*?CN=(.*?),.*/,'\1')
                   end
                   listOfUsers << {:name => entry.samaccountname.first, :groups => groups}
                else
                   listOfUsers << {:name => entry.samaccountname.first, :groups => []} # corner case with a user having no groups.
                end
             end
         end
      end 

      return listOfUsers
  end

  private

  def initialize(entry)
    @entry = entry

    self.class.class_eval do
      generate_single_value_readers
      generate_multi_value_readers
    end

    #@entry = nil
  end

  def self.generate_single_value_readers
    ATTR_SV.each_pair do |k, v|
      val, block = Array(v)
      define_method(k) do
        if @entry.attribute_names.include?(val)
          if block.is_a?(Proc)
            return block[@entry.send(val).first.to_s]
          else
            return @entry.send(val).first.to_s
          end
        else
          return ''
        end
      end
    end
  end

  def self.generate_multi_value_readers
    ATTR_MV.each_pair do |k, v|
      val, block = Array(v)
      define_method(k) do
        if @entry.attribute_names.include?(val)
          if block.is_a?(Proc)
            return @entry.send(val).collect(&block)
          else
            return @entry.send(val)
          end
        else
          return []
        end
      end
    end
  end

end
