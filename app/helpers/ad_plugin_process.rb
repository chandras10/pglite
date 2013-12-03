class String
  def processID?
    Float(self) != nil rescue false
  end
end

class AdPluginProcess
    
    PROCESS_NAME = "Active Directory Plugin"
    SERVICE_NAME = "adplugin"

    BACKEND_EXE = "/usr/local/bin/i7ADPlugin"
    BACKEND_EXE_ARGS = " -daemon"
    
    NUM_RETRIES = 3 # number of retries to attempt while starting the  process.
    SLEEP_INTERVAL = 5 # Number of seconds to wait between retries

    def name
      return PROCESS_NAME
    end

    def id
      return SERVICE_NAME
    end

    def status
      output = %x(pidof #{BACKEND_EXE} 2>&1)
      result =$?.success?

      if (result == false) && output.empty?
      	 output = "#{BACKEND_EXE} is not running."
      end

      return result, output
    end

    def start
      # Start the backend application. This function will make a few attempts to start the process before giving up.
      #
      result = false
      NUM_RETRIES.times do 
        output = %x(#{BACKEND_EXE} #{BACKEND_EXE_ARGS} 2>&1)
        result=$?.success?
        return false, "ERROR: Command: '#{BACKEND_EXE}' failed. Missing executable?" if (result == false)

        sleep(SLEEP_INTERVAL)
      
        result, output  = status
        return false, "ERROR: #{output}" if (result == false)      
        return true, "" if (output.processID?)
      end # do loop for retrying...

      return result, (result == true) ? "" : "ERROR: Failed to start the process: #{BACKEND_EXE}; #{output}"

    end #start

    def stop
      result, output = status
      if !output.processID? then
        return false, "ERROR: Unable to find the process id (pid) for  - #{BACKEND_EXE}"
      end
     
      processID = output.to_i
      output=%x(kill -s TERM #{processID} 2>&1)
      result =$?.success?
      if (result == false)
        return false, "ERROR: #{output}"
      else
        sleep(SLEEP_INTERVAL)
        %x(kill -9 #{processID}) # Issue a SIGKILL just to ensure the process does indeed terminate.
      end

      return true, ""
    end

    def restart
      result, output = status
      # if the backend isnt running, just start it and quit.
      if !output.processID? then
        return start
      end

      result, output = stop
      return result, output if (result == false)
     
      return start
    end

    def toggle
    	result, output = status
    	if (result == true)
    		return stop
    	else
    		return start
    	end
    end


end