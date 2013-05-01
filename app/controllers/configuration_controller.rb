require 'json'
require 'builder'

class ConfigurationController < ApplicationController

  def show_policy
  	#
  	# Constants
  	#
  	@sourceChoices = [
        	            ['Device Name',  ['Desktop/Laptop', 'MobileDevice'] ],
        	            ['Device Type',   ['iPad', 'iPhone', 'Android', 'Nokia5800', 'Windows 7'] ],
        	            ['Operating System', ['iOS', 'Android', 'Windows', 'Linux'] ],
        	            ['User Role', [ 'Employee', 'Manager', 'Guest'] ],
        	            ['User', ['chandra.m', 'sachin.s', 'srinivas.g', 'jagadeesh.mr'] ],
        	            ['Location', [ 'i7Net', 'GuestNet'] ]
        	         ]
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
    		   when "DeviceName"
    		      sourceHash[ref] = {"type"=>"DeviceName", "attrName"=>"name", "attrValue"=>value, "attrNeg"=>negation}
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
    policyXML.instruct! :xml, :version => "1.1", :encoding => "US-ASCII"
    
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
    			else
    			   policyXML.tag!(value['type'], value['attrName']=>value['attrValue'])
    			end
    		}
    	end
        
        ruleCounter=0
        policyXML.Policy do
           @policyJSON.each do |rule|
        	   policyXML.PolicyRule("position"=>"#{ruleCounter}", "id"=>"Rule#{ruleCounter+1}", "log"=>rule['log'], "action"=>rule['action']) {
                   ruleArray[ruleCounter]['sources'].each do |source|
                   	   policyXML.Src("neg"=>sourceHash[source]['attrNeg']) {
                   	   	  policyXML.ObjectRef("ref"=>source)
                   	   }
                   end
                   ruleArray[ruleCounter]['destinations'].each do |dest|
                   	   policyXML.Dst("neg"=>destHash[dest]['attrNeg']) {
                   	   	  policyXML.ObjectRef("ref"=>dest)
                   	   }
                   end
                   ruleCounter += 1
        	   }
           end
        end

    end

    @policyXMLFile = "my_xml_data_file.xml"
    file = File.new(@policyXMLFile, "w")
    file.write(policyXML)
    file.close
  end
end
