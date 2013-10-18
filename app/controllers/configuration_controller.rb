require 'json'
require 'builder'
require 'rexml/document'
require 'nokogiri'

class ConfigurationController < ApplicationController

  # This skip filter(below) is needed. Else, a warning - 'Cant verify CSRF token authenticity'
  # gets generated while saving the PG policy. This will lead to deleting the user cookie
  # in applicationcontroller and then a crash while trying to save the policy.
  skip_before_filter  :verify_authenticity_token

  include SessionsHelper 
  before_filter :signed_in_user, only: :edit_policy
  before_filter :admin_user, only: :save_policy

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

end
