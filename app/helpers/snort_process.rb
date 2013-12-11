require 'backend_process'

class SnortProcess < ServiceProcess
  
  def initialize
    @processName = "Snort"
    @serviceName = "snort"
    @exeName = ""
    @exeArgs = ""
  end

end