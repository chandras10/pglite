require 'json'
require 'builder'
require 'rexml/document'

class ConfigurationController < ApplicationController

  include REXML

  def edit_policy

    @fwObjects = Hash.new
    @fwRules = Array.new

    if (!File.exist?(Rails.configuration.peregrine_policyfile)) then
        #
        # Missing policy file?
        #
        @fwRules << {
                      "id" => "Rule1",
                      "position" => "0",
                      "sources" => [],
                      "destinations" => [],
                      "log" => "false",
                      "action" => "allow"
        }

        return;

    end

    file = File.new(Rails.configuration.peregrine_policyfile)
    xmldoc = Document.new(file)

    xmldoc.elements.each("FWPolicy/FWObject") do |obj|
        objType = obj.attributes["type"].downcase

        if (objType == "portlist") then 
           objType = "portrange"
        elsif (objType == "ipv4list") then
           objType = "ipv4"
           obj.attributes["value"] = obj.attributes["value"].gsub(" or ", ", ")
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

            sourceArray << { "neg" => src.attributes["neg"].downcase,  "references" => objArray }
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

            destArray << { "neg" => dst.attributes["neg"].downcase,  "references" => objArray }
        end
        destArray << {"references" => ["Any"]} if (destArray.empty?)

        @fwRules << {
                      "id" => rule.attributes["id"],
                      "position" => rule.attributes["position"],
                      "sources" => sourceArray,
                      "destinations" => destArray,
                      "log" => rule.attributes["log"].downcase,
                      "action" => rule.attributes["action"].downcase
        }


    end

  end #policy

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
                         "devicetype" => "DeviceType",
                         "osversion" => "OSVersion",
                         "username" => "UserName",
                         "userrole" => "UserRole",
                         "location" => "Location"
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
          policyXML.FWObject('id' => obj['id'], 'type' => objTypeMappings[obj['type']], 'value' => obj['value'])

          if (obj['type'] == "ipv4list") then
             obj['value'] = obj['value'].gsub(" or ", ", ")
             obj['type'] = 'ipv4'
          elsif (obj['type'] == "portlist") then
             obj['type'] = 'portrange'
          end

          @fwObjects[obj['id']] = {"type" => obj['type'], "value" => obj['value']}
       end
       
       policyXML.Policy do
          policyJSON["rules"].each do |rule|
             logger.debug("ACTION = #{rule['action']}")
             sourceArray = Array.new
             destArray = Array.new

             policyXML.PolicyRule("position"=>rule["position"], "id"=>rule["id"], "log"=>rule["log"].capitalize, "action"=>rule["action"].downcase) {
                rule["sources"].each do |src|
                   policyXML.Src("neg"=>src["negation"].capitalize) {
                      policyXML.ObjectRef("ref"=>src["ref"])
                      sourceArray << { "neg" => src["neg"],  "references" => [src["ref"]] }
                   }
                end
                rule["destinations"].each do |dst|
                   policyXML.Dst("neg"=>dst["negation"].capitalize) {
                      policyXML.ObjectRef("ref"=>dst["ref"])
                      destArray << { "neg" => dst["neg"],  "references" => [dst["ref"]] }
                   }
                end
             }

             @fwRules << {
                      "id" => rule["id"],
                      "position" => rule["position"],
                      "sources" => sourceArray,
                      "destinations" => destArray,
                      "log" => rule["log"].downcase,
                      "action" => rule["action"].downcase
             }

          end
       end
    end

    #
    # HACK - Just to get the new rule addition working for now.
    #
    if (params[:new_rule] == "y") then
       @fwRules.unshift({
                      "id" => "Rule" + (1000 + Random.rand(100)).to_s,
                      "position" => "0",
                      "sources" => [],
                      "destinations" => [],
                      "log" => "false",
                      "action" => "allow"
        })
        render :edit_policy
        return

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
    render :edit_policy
  end

end
