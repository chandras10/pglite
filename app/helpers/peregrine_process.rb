require 'backend_process'

class PeregrineProcess < SimpleProcess
  
  def initialize
    @processName = "Peregrine"
    @serviceName = "pgguard"
    @exeName = "/usr/local/bin/pgguard"
    @exeArgs = " -daemon"
  end

end
