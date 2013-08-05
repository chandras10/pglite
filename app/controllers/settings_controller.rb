require 'json'
require 'builder'
require 'rexml/document'
require 'nokogiri'
require 'yaml'

class SettingsController < ApplicationController

skip_before_filter  :verify_authenticity_token
  
  include SessionsHelper
  before_filter :signed_in_user, only: :settings_menu
  before_filter :admin_user, only: :save_settings
  
  include REXML

  def settings_menu

    @ldapconfig = Hash.new

    @pgconfig = Hash.new

    @homenetips = Homenet.all

    if (!File.exist?(Rails.configuration.peregrine_configfile)) then
        return;
    end
    xmlfile = File.new(Rails.configuration.peregrine_configfile)
    xmldoc = Document.new(xmlfile)

    xmldoc.root.elements['//pgguard'].elements.each do | elem |
         @pgconfig[elem.name] =  elem.text
    end

    if (!File.exist?(Rails.configuration.peregrine_ldapfile)) then
        return;
    end
 

    ldapfile = File.open(Rails.configuration.peregrine_ldapfile)
    yp = YAML::load_documents( ldapfile ) { |doc|
       @ldapconfig["server"] = doc['server']
       @ldapconfig["port"] = doc['port']
       @ldapconfig["base"] = doc['base']
       @ldapconfig["domain"] = doc['domain']
}
  end

  def save_settings

    @pgconfig = Hash.new
    @ldapconfig = Hash.new

    @homenetips = Homenet.all

    if (params[:configtype] == "PGGUARD") then 
    @doc = Nokogiri::XML(File.open(Rails.configuration.peregrine_configfile))
    interface = @doc.at_css "interface"
    eas = @doc.at_css "easAuthorizationEnabled"
    logmask = @doc.at_css "logmask"
    probeInterval = @doc.at_css "probeInterval"
    statUpdateInterval = @doc.at_css "statUpdateInterval"

    interface.content = params[:interface]
    eas.content = params[:easAuthorizationEnabled]
    if (eas.content == "true") then
	eas.content = 1
    else
	eas.content = 0
    end
    logmask.content = params[:logmask]
    probeInterval.content = params[:probeInterval]
    statUpdateInterval.content = params[:statUpdateInterval]
    File.open(Rails.configuration.peregrine_configfile, 'w') {|f| f.write(@doc) }
    end

    xmlfile = File.new(Rails.configuration.peregrine_configfile)
    xmldoc = Document.new(xmlfile)

    xmldoc.root.elements['//pgguard'].elements.each do | elem |
         @pgconfig[elem.name] =  elem.text
    end
   # @pgconfig.keys.sort

   if (File.exist?(Rails.configuration.peregrine_ldapfile)) then

   if (params[:configtype] == "AD") then
      data = YAML.load_file "#{Rails.root}/config/ldap.yml"
      data["server"] = params[:server]
      data["port"] = params[:port]
      data["base"] = params[:base]
      data["domain"] = params[:domain]

      File.open(Rails.configuration.peregrine_ldapfile) { |f| YAML.dump(data, f) }
    end

     
  ldapfile = File.open(Rails.configuration.peregrine_ldapfile)
  yp = YAML::load_documents( ldapfile ) { |doc|
       @ldapconfig["server"] = doc['server']
       @ldapconfig["port"] = doc['port']
       @ldapconfig["base"] = doc['base']
       @ldapconfig["domain"] = doc['domain']
  }

  end


    if (params[:configtype] == "HOMENET") then 
	ips = String.new(params[:homenetip]);
	ips.each_line("\r\n") do  |s| 
		s.delete!("\r\n")
		if (Homenet.find_by_net(s) == nil) then
			Homenet.create(net: s);	
		end
	end
        @homenetips = Homenet.all
    end
     render :settings_menu

  end

end
