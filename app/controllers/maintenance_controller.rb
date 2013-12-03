require 'fileutils'

class MaintenanceController < ApplicationController

  include SessionsHelper 
  before_filter :signed_in_user, only: [:maintenance, :health_check]
  before_filter :admin_user, only: [:update_license, :change_process_state]

  BACKEND_PROCESS_ARRAY = [ PeregrineProcess.new, 
                            AlertListenerProcess.new,
                            AdPluginProcess.new,
                            SnortProcess.new
  ]

  def maintenance
  	@license_info = Licenseinfo.first
  end

  def update_license

  	newLicenseFile = params[:licenseFile]
  	if newLicenseFile.nil? then
  	   fail "Please select the new license file and upload it."
  	end

  	#
  	# Read the uploaded file to a temporary location
  	#
  	File.open(Rails.root.join('tmp', newLicenseFile.original_filename), "wb+") do |f|
  	  f.write(newLicenseFile.read)
  	end

    #
    # Extract the exact product license file location from the configuration file.
    #
    oldLicenseFile = nil
    if File.exist?(Rails.configuration.peregrine_configfile) then
       xmlfile = File.new(Rails.configuration.peregrine_configfile)
       configHash = Hash.from_xml(xmlfile) || Hash.new
       if !configHash['pgguard'].nil? && !configHash['pgguard']['licensefile'].nil?
          oldLicenseFile = configHash['pgguard']['licensefile']
       end
    end

    if !oldLicenseFile.nil? && File.exist?(oldLicenseFile) then
    	File.rename(oldLicenseFile, oldLicenseFile + ".old")
    end

    FileUtils.mv(Rails.root.join('tmp', newLicenseFile.original_filename), oldLicenseFile)

    result, msg = PeregrineProcess.new.restart
    if (result == true) then
       redirect_to "/maintenance", notice: "License has been updated & Product restart succeeded."
    else
       fail msg
    end

  rescue => e
    redirect_to "/maintenance", :flash => {:error => "License update failed!! Error: #{e.message}"}
  end #update_license

  def health_check
  	 
  	 processHash = Hash.new
  	 BACKEND_PROCESS_ARRAY.each do |proc|
  	   processHash[proc.id] = [proc.name, proc.status].flatten
  	 end
  	 
     respond_to do |format|
       format.json { render json: processHash}
     end    

  end # health_check

  def change_process_state
  	processName = params["service_name"]
    
    bgProcess = BACKEND_PROCESS_ARRAY.select{ |p| p.id == processName }
    if !bgProcess.nil?
    	result, msg = bgProcess.toggle 
    else
    	result, msg = [false, "Unable to find service: #{processName}"]
    end

    if (result == true) then
       redirect_to "/maintenance"
    else
       redirect_to "/maintenance", :flash => {:error => "#{msg}"}
    end
  end

end
