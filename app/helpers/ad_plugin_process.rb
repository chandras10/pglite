require 'backend_process'

class AdPluginProcess < SimpleProcess
    
  def initialize
    @processName = "Active Directory Plugin"
    @serviceName = "adplugin"
    @exeName = "/usr/local/bin/i7ADPlugin"
    @exeArgs = " -daemon"
  end

end