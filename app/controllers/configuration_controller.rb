require 'json'
require 'builder'
require 'rexml/document'
require 'rexml/xpath'
require 'nokogiri'

class ConfigurationController < ApplicationController

  KEY_TO_LOGIN = Digest::SHA256.hexdigest("peregrineGuard User")
  KEY_TO_PASSWD = Digest::SHA256.hexdigest("peregrineGuard Password")

  # This skip filter(below) is needed. Else, a warning - 'Cant verify CSRF token authenticity'
  # gets generated while saving the PG policy. This will lead to deleting the user cookie
  # in applicationcontroller and then a crash while trying to save the policy.
  skip_before_filter  :verify_authenticity_token

  include SessionsHelper 
  before_filter :signed_in_user, only: [:edit_policy, :configuration, :alerts]
  before_filter :admin_user, only: [:save_policy, :save_configuration, :save_alerts]

  include REXML

  def edit_policy
    default_ANY_ANY_rule = {
                      "id" => "Rule1",
                      "position" => "0",
                      "sources" => [],
                      "destinations" => [],
                      "log" => "false",
                      "alert" => "false",
                      "action" => "allow"
    }

    @fwObjects = Hash.new
    @fwRules = Array.new

    if (!File.exist?(Rails.configuration.peregrine_policyfile)) then
        #
        # Missing policy file?
        #
        @fwRules << default_ANY_ANY_rule

        #
        # Default values for Device Authorization
        #
        id = Time.new.to_i
        authSources = Authsources.all
        authSources.each do |source|
           @fwObjects["obj_" + id.to_s] = {"type" => "devicestate", "value" => source.description} if !source.description.empty?
           id += 1
        end

        #
        # Default values for Operating System
        #
        operatingSystems = Deviceinfo.select("operatingsystem").where("operatingsystem is not NULL and operatingsystem <> ''").uniq
        operatingSystems.each do |rec|
           @fwObjects["obj_" + id.to_s] = {"type" => "osname", "value" => rec.operatingsystem }
           id += 1
        end

        render :policy
        return;
    end

    codes = IsoCountryCodes.for_select
    countryCodes = Hash.new
    codes.each do |c|
      countryCodes[c[1]] = c[0]
    end

    file = File.new(Rails.configuration.peregrine_policyfile)
    xmldoc = Document.new(file)

    xmldoc.elements.each("FWPolicy/FWObject") do |obj|
        objType = obj.attributes["type"].downcase

        if (objType == "portlist") then 
           objType = "portrange"
        elsif (objType == "ipv4list") then
           objType = "ipv4"
           obj.attributes["value"] = obj.attributes["value"].gsub(/\s+or\s+/, ", ")
        elsif (objType == "geolocation") then
           obj.attributes["value"] = "#{obj.attributes['value']} - #{countryCodes[obj.attributes['value']]}"
        end

        @fwObjects[obj.attributes["id"]] = {"type" => objType, "value" => obj.attributes["value"]}
    end

    #
    # Added any new Authorization sources (from the database) to the policy model.
    #
    dbAuthSources = Authsources.pluck(:description)
    policyAuthSources = Array.new
    @fwObjects.each do |k, v|
       if v["type"] == "devicestate"
         policyAuthSources << v["value"]
       end
    end

    newAuthSources = dbAuthSources - policyAuthSources
    id = Time.new.to_i
    newAuthSources.each do |n|
       @fwObjects["obj_" + id.to_s] = {"type" => "devicestate", "value" => n} if !n.empty?
       id += 1
    end

    xmldoc.elements.each("FWPolicy/Policy/PolicyRule") do |rule|
        sourceArray = Array.new
        rule.elements.each("Src") do |src|
            #
            # Each source node could have one or more Object references
            #
            objArray = Array.new
            src.elements.each("ObjectRef") do |objRef|
                 objArray << objRef.attributes["ref"]
            end

            sourceArray << { "operator" => src.attributes["operator"],  "references" => objArray }
        end

        destArray = Array.new
        rule.elements.each("Dst") do |dst|
            #
            # Each Destination node could have one or more Object references
            #
            objArray = Array.new
            dst.elements.each("ObjectRef") do |objRef|
                 objArray << objRef.attributes["ref"]
            end

            destArray << { "operator" => dst.attributes["operator"],  "references" => objArray }
        end

        @fwRules << {
                      "id" => rule.attributes["id"],
                      "position" => rule.attributes["position"],
                      "sources" => sourceArray,
                      "destinations" => destArray,
                      "log" => (rule.attributes["log"].present? ? rule.attributes["log"].downcase : "false"),
                      "alert" => (!rule.attributes["alert"].nil? ? rule.attributes["alert"].downcase : "false"),
                      "action" => rule.attributes["action"].downcase
        }
    end

    if (@fwRules.empty?) then
        @fwRules << default_ANY_ANY_rule
    end

    render :policy

  end # edit_policy routine

  def save_policy
    objTypeMappings = {
                         "any" => "Any",
                         "osname" => "OSName",
                         "portrange" => "PortRange",
                         "portlist" => "PortList",
                         "ipv4list" => "IPv4List",
                         "port" => "Port",
                         "ipv4subnet" => "IPv4Subnet",
                         "ipv4" => "IPv4",
                         "deviceclass" => "DeviceClass",
                         "devicestate" => "DeviceState",
                         "devicetype" => "DeviceType",
                         "osversion" => "OSVersion",
                         "dvi" => "DVI",
                         "dti" => "DTI",
                         "username" => "UserName",
                         "userrole" => "UserRole",
                         "location" => "Location",
                         "geolocation" => "GeoLocation"
                      }

    #
    # These data structures, below, are used to format the screen after saving the policy file.
    # Basically, the saved policy is redisplayed...
    #
    @fwObjects = Hash.new
    @fwRules = Array.new


    #
    # Assumption: JSON objected POSTed will always have a valid policy structure with at least one rule and
    # at least one source and destination ("ANY" could be the value, too)
    #
    policyJSON = JSON.parse params[:policy_json]

    policyXML = Builder::XmlMarkup.new(:indent => 1)
    policyXML.instruct! :xml, :version => "1.0", :encoding => "ISO-8859-1"
    policyXML.declare! :DOCTYPE, :FWPolicy, :SYSTEM, Rails.configuration.peregrine_policyfile_dtd

    # Enumerate all the sources and destinations as FWObject nodes
    policyXML.FWPolicy do
       policyJSON["objects"].each do |obj|

          if (obj['type'] == "geolocation") then
             policyXML.FWObject('id' => obj['id'], 'type' => objTypeMappings[obj['type']], 'value' => obj['value'].strip[0..1])
          else
             policyXML.FWObject('id' => obj['id'], 'type' => objTypeMappings[obj['type']], 'value' => obj['value'])
          end


          if (obj['type'] == "ipv4list") then
             obj['value'] = obj['value'].gsub(/\s+or\s+/, ", ")
             obj['type'] = 'ipv4'
          elsif (obj['type'] == "portlist") then
             obj['type'] = 'portrange'
          end

          @fwObjects[obj['id']] = {"type" => obj['type'], "value" => obj['value']}
       end
       
       policyXML.Policy do
          policyJSON["rules"].each do |rule|
             sourceArray = Array.new
             destArray = Array.new

             policyXML.PolicyRule("position"=>rule["position"], "id"=>rule["id"], "log"=>rule["log"].capitalize,  "alert"=>rule["alert"].capitalize, "action"=>rule["action"].downcase) {
                rule["sources"].each do |src|
                   policyXML.Src("operator"=>src["opr"]) {
                      policyXML.ObjectRef("ref"=>src["ref"])
                      sourceArray << { "operator" => src["opr"],  "references" => [src["ref"]] }
                   }
                end
                rule["destinations"].each do |dst|
                   policyXML.Dst("operator"=>dst["opr"]) {
                      policyXML.ObjectRef("ref"=>dst["ref"])
                      destArray << { "operator" => dst["opr"],  "references" => [dst["ref"]] }
                   }
                end
             }

             @fwRules << {
                      "id" => rule["id"],
                      "position" => rule["position"],
                      "sources" => sourceArray,
                      "destinations" => destArray,
                      "log" => rule["log"].downcase,
                      "alert" => rule["alert"].downcase,
                      "action" => rule["action"].downcase
             }


          end
       end
    end

    #
    # Before saving, rotate the files. Keep at least N versions of the file backed up.
    # N - could be defined in a config file
    #
    numOfBackups = 3
    savedfilename = Rails.configuration.peregrine_policyfile
    for i in (1..(numOfBackups-1))
       version = numOfBackups - i
       if (File.exists?(savedfilename+".#{version-1}")) then
           File.rename(savedfilename+".#{version-1}", savedfilename+".#{version}")
       end
    end
    #
    # Rename current policy as version "0"
    #
    if (File.exists?(savedfilename)) then
       File.rename(savedfilename, savedfilename+".0")
    end
    

    file = File.new(Rails.configuration.peregrine_policyfile, "w")
    file.write(policyXML.target!)
    file.close

    # Alert PG to now install the generated policy file
    system("#{Rails.configuration.peregrine_pgguard_alert_cmd}")

    #
    # redisplay the saved policy file
    #
    render :policy
  end

  def configuration
    if File.exist?(Rails.configuration.peregrine_configfile) then
       xmlfile = File.new(Rails.configuration.peregrine_configfile)
       configHash = Hash.from_xml(xmlfile)
    end

    @homeNets = Appipinternal.where(appid: 1)
    @byodNets = Appipinternal.where(appid: 2)

    if File.exist?(Rails.configuration.peregrine_adconfigfile) then
       xmlfile = File.new(Rails.configuration.peregrine_adconfigfile)
       configHash = Hash.new if configHash.nil?
       adPluginHash = Hash.from_xml(xmlfile)
       configHash["ad_plugin"] = adPluginHash["i7"]["server"]
    end

    if File.exist?(Rails.configuration.peregrine_plugin_maas360_config) then
       xmlfile = File.new(Rails.configuration.peregrine_plugin_maas360_config)
       configHash = Hash.new if configHash.nil?
       maas360Hash = Hash.from_xml(xmlfile)
       configHash["maas360"] = maas360Hash["maas360"]
    end

    respond_to do |format|
      format.html # configuration.html.erb
      format.json { render json: (configHash.nil? ? {} : configHash)}
    end    
  end

  def save_configuration
    ipv4_netmask_pattern = "(^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))\/((?:[0-9]|1[0-9]|2[0-9]|3[0-2]))$"
    paramHash = JSON.parse(params['tabParms'])
    pgConfig = paramHash['pgguard']
    if (!pgConfig.nil?)
       if !pgConfig['homeNets'].nil? 
          homeNets = pgConfig['homeNets'].split(';')
          ActiveRecord::Base.transaction do
            Appipinternal.delete_all(:appid => 1)
            homeNets.each do |homeNet|
              matchData = /#{ipv4_netmask_pattern}/.match(homeNet)
              Appipinternal.create(:iprange => matchData[1], :mask => matchData[2], :appid=>1, :port=>0)
            end
          end
          pgConfig.delete('homeNets') # No need to add this to config file after saving it to the database table.
       end

       if !pgConfig['byodNets'].nil? 
          byodNets = pgConfig['byodNets'].split(';')
          ActiveRecord::Base.transaction do
            Appipinternal.delete_all(:appid => 2)
            byodNets.each do |byodNet|
              matchData = /#{ipv4_netmask_pattern}/.match(byodNet)
              Appipinternal.create(:iprange => matchData[1], :mask => matchData[2], :appid=>2, :port=>0)
            end
          end
          pgConfig.delete('byodNets') # No need to add this to config file after saving it to the database table.
       end

       if !pgConfig['email'].nil? && !pgConfig['email']['smtp'].nil? && !pgConfig['email']['smtp']['password'].nil? && !pgConfig['email']['smtp']['password'].empty? then
          pgConfig['email']['smtp']['password'] = encrypt(pgConfig['email']['smtp']['password'])
       end

       if File.exist?(Rails.configuration.peregrine_configfile) then
          xmlfile = File.new(Rails.configuration.peregrine_configfile)
          configHash = Hash.from_xml(xmlfile) || Hash.new
          if !configHash['pgguard'].nil?
             configHash = configHash['pgguard']
          end
       else
          configHash = Hash.new
       end

       #
       # Combine the UI parameters (via HTTP request) with the configuration on the file.
       #
       configHash = configHash.merge(pgConfig)       
       file = File.new(Rails.configuration.peregrine_configfile, "w")
       file.write(configHash.to_xml({:root => 'pgguard', :skip_types => true}))
       file.close

    end # pg configuration?

    adPluginConfig = paramHash['ad_plugin']
    if (!adPluginConfig.nil?)
       if (!adPluginConfig['password'].nil? && !adPluginConfig['password'].empty?)
          adPluginConfig['password'] = encrypt(adPluginConfig['password'])
       end

       if File.exist?(Rails.configuration.peregrine_adconfigfile) then
          xmlfile = File.new(Rails.configuration.peregrine_adconfigfile)
          pluginHash = Hash.from_xml(xmlfile) || Hash.new
          if !pluginHash['i7'].nil?
             if !pluginHash['i7']['server'].nil?
                serverHash = pluginHash['i7']['server']
             else
                serverHash = Hash.new
             end
          else
             serverHash = Hash.new
          end
       else
          pluginHash = Hash.new
          pluginHash['i7'] = Hash.new
          serverHash = Hash.new
       end
       pluginHash['i7']['server'] = serverHash.merge(adPluginConfig)       
       file = File.new(Rails.configuration.peregrine_adconfigfile, "w")
       file.write(pluginHash['i7'].to_xml({:root => 'i7', :skip_types => true}))
       file.close
    else
       #
       # If the user disables this plugin, then just remove the configuration file since it is not needed.
       # It will be created again with the user provided parameters when this plugin is enabled in the UI.
       if File.exist?(Rails.configuration.peregrine_adconfigfile) then
          File.delete(Rails.configuration.peregrine_adconfigfile)
       end
    end

    #
    # If the Login Authentication method changes, then log out the current user so that on the relogin, the changed auth method is employed.
    #
    if !pgConfig.nil? && !pgConfig['authentication'].nil? 
       if !pgConfig['authentication']['ldap'].nil? && (Pglite.config.authentication != "ActiveDirectory") ||
          (pgConfig['authentication'].empty? && (Pglite.config.authentication != "Local"))
          Pglite.config.authentication = pgConfig['authentication'].empty? ? "Local" : "ActiveDirectory"
          sign_out
       end
    end

    #
    # MDM plugin changes to be hardened
    #
    if !pgConfig.nil? && !pgConfig['enableMDMInterface'].nil? && (pgConfig['enableMDMInterface'] == true)
       if !paramHash['maas360'].nil? then
          if !paramHash['maas360']['MAAS_ADMIN_PASSWORD'].nil?
             paramHash['maas360']['MAAS_ADMIN_PASSWORD'] = encrypt(paramHash['maas360']['MAAS_ADMIN_PASSWORD'])
          end
       end
       if File.exist?(Rails.configuration.peregrine_plugin_maas360_config) then
          xmlfile = File.new(Rails.configuration.peregrine_plugin_maas360_config)
          mdmHash = Hash.from_xml(xmlfile) || Hash.new
          if !mdmHash['maas360'].nil?
             maas360Hash = mdmHash['maas360']
          else
             maas360Hash = Hash.new
          end
       else
          mdmHash = Hash.new
          mdmHash['maas360'] = maas360Hash = Hash.new
       end
       mdmHash['maas360'] = maas360Hash.merge(paramHash['maas360'])       
       file = File.new(Rails.configuration.peregrine_plugin_maas360_config, "w")
       file.write(mdmHash['maas360'].to_xml({:root => 'maas360', :skip_types => true}))
       file.close
    end
    
    if paramHash['restart'] == true
       result, msg = PeregrineProcess.new.restart
       if (result == true) then
          redirect_to "/settings", notice: "Saved the configuration changes. Restart succeeded."
       else
          redirect_to "/settings", :flash => {:error => "Saved the configuration changes. Restart failed - #{msg}"}
       end
    else
       redirect_to "/settings", notice: "Saved the configuration changes."
    end

  end

  def alerts
    alertClasses = I7alertclassdef.select("id, description").
                   where("id NOT in (#{Rails.configuration.i7alerts_ignore_classes.join('')})").order("id")

    alertDefArray = Array.new

    alertClasses.each do | alertClass |
    
      alertDefs = I7alertdef.select("id, description, active, email").where("classid = ?", alertClass.id).order("active DESC, id")
      children = Array.new
      alertDefs.each do |alert|
         children << { title: alert.description, key: alert.id, OTHER: [alert.active, alert.email]}
      end
      alertDefArray << {
            title: "<h6>#{alertClass.description}</h6>",
            key: alertClass.id,
            hideCheckbox: true,
            unselectable: true,
            folder: true,
            children: children
      }
    end

    respond_to do |format|
       format.json { render json: alertDefArray}
    end
  end

  def save_alerts

    noticeMsg = "Saved the changes."
    ActiveRecord::Base.transaction do
      # Just enable all alerts, to begin with
      I7alertdef.update_all({:active => true, :email => false})

      if (!params['inactiveids'].empty?)
        I7alertdef.update_all({:active => false}, "id IN (#{params['inactiveids']})")
        Delayed::Job.enqueue I7alertJob.new(params['inactiveids'])
        noticeMsg = "Some alerts have been disabled. DVI and/or DTI will be recalculated for devices which might have previously generated these disabled alerts..."
      end

      if (!params['emailids'].empty?)
        I7alertdef.update_all({:email => true}, "id IN (#{params['emailids']})")
      end
    end # End of DB transaction

    if params['restart'] == "true"
       result, msg = PeregrineProcess.new.restart
       noticeMsg += " Restart failed - #{msg}" if (result == false)
    end

    redirect_to "/settings", notice: noticeMsg
  end

  private
    def encrypt(str)

      return str if (str.nil? or str.empty?)
      #
      # Encrypt the password only if it has changed. I have added a kludge in the coffeescript to suffix
      # the value with _CHG_ to indicate that it has changed
      #
      matchDef = /(.*)_CHG_$/.match(str)
      if matchDef.nil?
         return  str # passwd didnt change, so return the already encrypted passwd as is.
      elsif matchDef[1].nil?
         return '' # maybe the user just blanked out the password and left it empty.
      end

      #Base64.encode64(Encryptor.encrypt(str, :key => KEY_TO_PASSWD).force_encoding('UTF-8'))
      algorithm = "AES-256-CBC"
      cipher = OpenSSL::Cipher::Cipher.new(algorithm)
      cipher.encrypt
      cipher.key = KEY_TO_PASSWD

      encryptedStr = cipher.update(matchDef[1])
      encryptedStr << cipher.final

      Base64.strict_encode64(encryptedStr)
    end
end
