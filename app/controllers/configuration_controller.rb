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
                      "sources" => [{"references" => ["Any"]}],
                      "destinations" => [{"references" => ["Any"]}],
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
        sourceArray << {"references" => ["Any"]} if (sourceArray.empty?)

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
                         "osname" => "OSName",
                         "portrange" => "PortRange",
                         "portlist" => "PortList",
                         "ipv4list" => "IPv4List",
                         "port" => "Port",
                         "ipv4subnet" => "IPv4Subnet",
                         "ipv4" => "IPv4",
                         "deviceclass" => "DeviceClass",
                         "devicetype" => "Device Type",
                         "osversion" => "OSVersion",
                         "username" => "UserName",
                         "userrole" => "UserRole",
                         "location" => "Location"
                      }

    @fwObjects = Hash.new
    @fwRules = Array.new


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
                      "log" => rule["log"],
                      "action" => rule["action"]
             }

          end
       end
    end

    #file = File.new(Rails.configuration.peregrine_policyfile, "w")
    file = File.new("/tmp/chandra.xml", "w")
    file.write(policyXML.target!)
    file.close

    # Alert PG to now install the generated policy file
    system("#{Rails.configuration.peregrine_pgguard_alert_cmd}")

    @fwRules << {
                      "id" => "Rule1",
                      "position" => "0",
                      "sources" => [{"references" => ["Any"]}],
                      "destinations" => [{"references" => ["Any"]}],
                      "log" => "false",
                      "action" => "allow"
   }
    render :edit_policy
  end

  def show_policy

    #
    # Currently, we are hardcoding the choices that user can make on what is a "Source"/"Destination" for a given policy rule.
    # SOURCE is basically one of the following types. On selecting a "type", the user will be presented with some suggestions
    # that are pulled out of the database for that attribute. For example, if "Operating System" is picked from the dropdown, then the user
    # will be given choices like ["Android", "iOS", "Linux"] depending what is stored in the database for the detected devices. User has
    # the freedom to pick one of these values or enter a new value too.
    #
    sourceChoiceTypes = ['Device Class', 'Device Type', 'Operating System', 'User Role', 'User', 'Location']
    attrList = ["deviceclass", "devicetype", "operatingsystem", "groupname", "username", "location"]
    srcChoicesHash = Hash.new
    attrList.each { |i| srcChoicesHash[i] = Array.new }
    detectedDevices = Deviceinfo.all
    detectedDevices.each do |record|
       attrList.each do |attr|
           srcChoicesHash[attr] << record[attr] if !record[attr].empty?
       end
    end

    @sourceChoices = Array.new
    for i in 0..(sourceChoiceTypes.length-1) 
        @sourceChoices << [sourceChoiceTypes[i], srcChoicesHash[attrList[i]].uniq{|a| a.lstrip}]
    end

    @destinationChoices = ["IP Address", "IP SubNet", "Port", "Range of Ports"]

    
  end

  def create_policy
  	@policyJSON = JSON.parse params[:policy_json]

    ruleArray = Array.new
    sourceHash = Hash.new
    destHash = Hash.new

    objectRefCount = 1
    @policyJSON.each do |rule|
    	sources = rule['sources']
        
        srcRefs = Array.new
    	sources.each do |source|
    		type = source['type'].gsub(/\s+/, "")
   		    value = if (source['value'].empty?) then "Any" else  source['value'].lstrip end
    		if (value[0] == '!') then 
    			negation = "true"
    			value = value.sub('!',"")
    		else
    		    negation = "false"
    		end

            
            ref = "fwobject_#{objectRefCount}"
            srcRefs << ref

    		case type
    		   when "DeviceClass"
    		      sourceHash[ref] = {"type"=>"DeviceClass", "attrName"=>"class", "attrValue"=>value, "attrNeg"=>negation}
    		   when "DeviceType"
    		   	  sourceHash[ref] = {"type"=>"DeviceType", "attrName"=>"type", "attrValue"=>value, "attrNeg"=>negation}
    		   when "OperatingSystem"
    		   	  sourceHash[ref] = {"type"=>"OSName", "attrName"=>"os", "attrValue"=>value, "attrNeg"=>negation}
    		   when "UserRole"
    		   	  sourceHash[ref] = {"type"=>"UserRole", "attrName"=>"role", "attrValue"=>value, "attrNeg"=>negation}
    		   when "User"
    		      sourceHash[ref] = {"type"=>"UserName", "attrName"=>"name", "attrValue"=>value, "attrNeg"=>negation}
    		   when "Location"
                  sourceHash[ref] = {"type"=>"Location", "attrName"=>"location", "attrValue"=>value, "attrNeg"=>negation}
    	    end

    	    objectRefCount += 1
    	end

    	destinations = rule['destinations']
    	destRefs = Array.new
    	destinations.each do |dest|
    		type = dest['type'].gsub(/\s+/, "")
    		value = if (dest['value'].empty?) then "Any" else  dest['value'].lstrip end
    		if (value[0] == '!') then 
    			negation = "true"
    			value = value.sub('!',"")
    		else
    		    negation = "false"
    		end

            ref = "fwobject_#{objectRefCount}"
            destRefs << ref
    		case type
    		   when "IPAddress"
    		   	  destHash[ref] = {"type"=>"IPv4", "attrName"=>"address", "attrValue"=>value, "attrNeg"=>negation}
    		   when "IPSubNet"
    		   	  destHash[ref] = {"type"=>"IPv4Subnet", "attrName"=>"address", "attrValue"=>value, "attrNeg"=>negation}
    		   when "Port"
    		   	  destHash[ref] = {"type"=>"Port", "attrName"=>"port", "attrValue"=>value, "attrNeg"=>negation}
    		   when "RangeofPorts"
    		   	  destHash[ref] = {"type"=>"PortRange", "attrName"=>"", "attrValue"=>value, "attrNeg"=>negation}
    		end

    		objectRefCount += 1
    	end

        ruleArray << {'sources'=>srcRefs, 'destinations'=>destRefs}

    end # next Rule

    policyXML = Builder::XmlMarkup.new(:indent => 1)
    policyXML.instruct! :xml, :version => "1.0", :encoding => "ISO-8859-1"
    policyXML.declare! :DOCTYPE, :FWPolicy, :SYSTEM, Rails.configuration.peregrine_policyfile_dtd

    # Enumerate all the sources and destinations as FWObject nodes
    policyXML.FWPolicy do
    	sourceHash.each do |id, value|
    		policyXML.FWObject('id'=>id) {
    			policyXML.tag!(value['type'], value['attrName']=>value['attrValue'])
    		}
    	end
    	destHash.each do |id, value|
    		policyXML.FWObject('id'=>id) {
    			if (value['type'] == "IPv4Subnet") then
    				value['attrValue'] =~ /(.*)\/(.*)/
    				policyXML.tag!(value['type'], 'address'=>$1, 'netmask'=>$2)
    			elsif (value['type'] == "PortRange") then
    				portsArray = value['attrValue'].split(/,/)
    				policyXML.PortList do
    					portsArray.each do |port|
    						policyXML.Port("port"=> port.lstrip)
    					end
    			    end
    		    else
    			   policyXML.tag!(value['type'], value['attrName']=>value['attrValue'])
    			end
    		}
    	end
        
        ruleCounter=0
        policyXML.Policy do
           @policyJSON.each do |rule|
        	   policyXML.PolicyRule("position"=>"#{ruleCounter}", "id"=>"Rule#{ruleCounter+1}", "log"=>rule['log'].capitalize, "action"=>rule['action'].downcase) {
                   ruleArray[ruleCounter]['sources'].each do |source|
                   	   policyXML.Src("neg"=>sourceHash[source]['attrNeg'].capitalize) {
                   	   	  policyXML.ObjectRef("ref"=>source)
                   	   }
                   end
                   ruleArray[ruleCounter]['destinations'].each do |dest|
                   	   policyXML.Dst("neg"=>destHash[dest]['attrNeg'].capitalize) {
                   	   	  policyXML.ObjectRef("ref"=>dest)
                   	   }
                   end
                   ruleCounter += 1
        	   }
           end
        end

    end

    file = File.new(Rails.configuration.peregrine_policyfile, "w")
    file.write(policyXML.target!)
    file.close

    # Alert PG to now install the generated policy file
    system("#{Rails.configuration.peregrine_pgguard_alert_cmd}")

  end
end
