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
  @restartrequired = false

  def settings_menu

   restart = params[:restart] 

   if (restart == "true") then
	s=%x(cat #{"/usr/local/var/pgguard/pgguard.pid"}  | xargs ps)
    	check_run = (s =~ /pgguard/)

        if check_run
           pid = %x(cat #{"/usr/local/var/pgguard/pgguard.pid"})
           pid_i = pid.to_i
           if pid_i > 0
                system ("kill -s TERM #{pid_i}")
            end
        end
        system("/usr/local/bin/pgguard -daemon");
        sleep(3)
    end

    @ldapconfig = Hash.new

    @pgconfig = Hash.new

    @pgeventconfig = Hash.new

    @homenetips = Homenet.all

    @restartrequired = false

    if (!File.exist?(Rails.configuration.peregrine_configfile)) then
        return;
    end
    xmlfile = File.new(Rails.configuration.peregrine_configfile)
    xmldoc = Document.new(xmlfile)

    xmldoc.root.elements['//pgguard'].elements.each do | elem |
         @pgconfig[elem.name] =  elem.text
    end

    @pgeventconfig = {"ip" => "", "username" => "", "password" => "", "polltime" => "", "ssid" => ""}
    if (File.exist?(Rails.configuration.peregrine_adconfigfile)) then
    	    adxmlfile = File.new(Rails.configuration.peregrine_adconfigfile)
	    adxmldoc = Document.new(adxmlfile)

	    adxmldoc.root.elements['//i7/server'].elements.each do | elem |
	         @pgeventconfig[elem.name] =  elem.text
	    end
    end

    @ldapconfig = {"server" => "", "port" => "", "base" => "", "domain" => ""} 

    if (File.exist?(Rails.configuration.peregrine_ldapfile)) then
    	ldapfile = File.open(Rails.configuration.peregrine_ldapfile)
    	yp = YAML::load_documents( ldapfile ) { |doc|
       		@ldapconfig["server"] = doc['server']
       		@ldapconfig["port"] = doc['port']
      		@ldapconfig["base"] = doc['base']
       		@ldapconfig["domain"] = doc['domain']
       		}
     end
  end

  def save_settings

    @pgconfig = Hash.new
    @ldapconfig = Hash.new
 
    @pgeventconfig = Hash.new

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

   @restartrequired = true
    end



    if (params[:configtype] == "PLUGINAD") then
    	@plugindoc = Nokogiri::XML(File.open(Rails.configuration.peregrine_adconfigfile))
    
    	ip =  @plugindoc.at_css "ip"
    	username  = @plugindoc.at_css "username"
    	password  = @plugindoc.at_css "password"
    	polltime =  @plugindoc.at_css "polltime"
    	ssid =  @plugindoc.at_css "ssid"

    	ip.content = params[:ip]
    	username.content = params[:username]
    	password.content = params[:password]
    	polltime.content = params[:polltime]
    	ssid.content = params[:ssid]

    	File.open(Rails.configuration.peregrine_adconfigfile, 'w') {|f| f.write(@plugindoc) }

    	xmlfile = File.new(Rails.configuration.peregrine_adconfigfile)
   	xmldoc = Document.new(xmlfile)

    	xmldoc.root.elements['//i7/server'].elements.each do | elem |
         	@pgeventconfig[elem.name] =  elem.text
    	end

	s=%x(cat #{"/usr/local/etc/i7ADPlugin/i7ADPlugin.pid"}  | xargs ps)
        check_run = (s =~ /i7ADPlugin/)

        if check_run
           pid = %x(cat #{"/usr/local/etc/i7ADPlugin/i7ADPlugin.pid"})
           pid_i = pid.to_i
           if pid_i > 0
                system ("kill -9 #{pid_i}")
            end
        end
        system("/usr/local/bin/i7ADPlugin -daemon");
        sleep(3)

        @restartrequired = false
    end


   if (params[:configtype] == "AD") then
      data = Hash.new
      data["server"] = params[:server]
      data["port"] = params[:port]
      data["base"] = params[:base]
      data["domain"] = params[:domain]
      if (data["server"] != "" && data["port"] != "" && data["base"] != "" && data["domain"] != "") then
      		File.open(Rails.configuration.peregrine_ldapfile, "w") { |f| YAML.dump(data, f) }
    		end
                @restartrequired = true
      end

    if (File.exist?(Rails.configuration.peregrine_ldapfile)) then
  	ldapfile = File.open(Rails.configuration.peregrine_ldapfile)
	  yp = YAML::load_documents( ldapfile ) { |doc|
       		@ldapconfig["server"] = doc['server']
       		@ldapconfig["port"] = doc['port']
       		@ldapconfig["base"] = doc['base']
       		@ldapconfig["domain"] = doc['domain']
  	}
    else 
   		 @ldapconfig = {"server" => "", "port" => "", "base" => "", "domain" => ""}
    end

  



    if (params[:configtype] == "HOMENET") then 
	ips = String.new(params[:homenetip]);
	Homenet.delete_all
	ips.each_line("\r\n") do  |s| 
		s.delete!("\r\n")
		Homenet.create(net: s);	
	end
        @homenetips = Homenet.all
    end
     render :settings_menu

  end


  def alerts
    alertClasses = I7alertclassdef.select("id, description").
                   where("id NOT in (#{Rails.configuration.i7alerts_ignore_classes.join('')})")

    alertDefArray = Array.new

    alertClasses.each do | alertClass |
    
      alertDefs = I7alertdef.select("id, active, description").where("classid = ?", alertClass.id)
      children = Array.new
      alertDefs.each do |alert|
         children << { title: "#{alert.id}: #{alert.description}", id: alert.id, select: alert.active}
      end
      alertDefArray << {
            title: "<h6>#{alertClass.id}: #{alertClass.description}</h6>",
            id: alertClass.id,
            hideCheckbox: true,
            unselectable: true,
            children: children
      }
    end

    respond_to do |format|
       format.json { render json: alertDefArray}
    end
  end

  def save_alerts
     Rails.logger.debug "Alerts to Save: #{params['ids']}"

     if (!params['activeids'].empty?) 
        I7alertdef.update_all({:active => true}, "id IN (#{params['activeids']})")
     end

     if (!params['disableids'].empty?)
        disableI7Alerts(params['disableids'])
     end
     
     settings_menu
     render :settings_menu
  end

  private
  def disableI7Alerts(ids)

    if ids.nil? || ids.empty?
       return
    end
    
    I7alertdef.update_all({:active => false}, "id IN (#{ids})")

    macIDs = I7alert.where("id IN (#{ids})").pluck('srcmac').uniq

    if (macIDs.empty?)
       return
    end

    #I7alert.update_all({:srcport => 999 }, "id IN (#{ids})")
    #Deviceinfo.update_all({:updated_at => Time.now}, "macid IN ('" + macIDs.join("','") + "')")
    I7alert.delete_all("id IN (#{ids})")
    macIDs.each do |device|
       ActiveRecord::Base.connection.execute("SELECT * FROM computeDVI('#{device}')")
       ActiveRecord::Base.connection.execute("SELECT * FROM computeDTI('#{device}')")
    end

  end

end
