require 'backend_process'

class AuthDevParser < SimpleProcess
    
  def initialize
    @processName = "Device Authorization List Parser"
    @serviceName = "authDevParser"
    @exeName = "/usr/local/bin/authDevParser"
    @exeArgs = ""

    @importFile = "/usr/local/etc/pgguard/mac_list.txt"
  end

  def status
  	return true, ""
  end

  def importDevicesFromFile
  	@importFile
  end

end