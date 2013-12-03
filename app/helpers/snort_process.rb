class SnortProcess
    
    PROCESS_NAME = "Snort"
    SERVICE_NAME = "snort"

    BACKEND_EXE = " "
    BACKEND_EXE_ARGS = " "
    NUM_RETRIES = 3 # number of retries to attempt while starting the backend process.
    SLEEP_INTERVAL = 5 # Number of seconds to wait between retries

    def name
      return PROCESS_NAME
    end

    def id
      return SERVICE_NAME
    end

    def status
      output = %x(service #{SERVICE_NAME} status 2>&1)
      result =$?.success?
      return result, output     
    end

    def start
      # Start the backend application. This function will make a few attempts to start the process before giving up.
      #
      result = false
      NUM_RETRIES.times do 
        output = %x(service #{SERVICE_NAME} start 2>&1)
        result=$?.success?
        return false, "ERROR: Command: '#{SERVICE_NAME}' start failed. Missing service?" if (result == false)

        sleep(SLEEP_INTERVAL)
      
        result, output  = status
        return false, "ERROR: #{output}" if (result == false)      
        return true, "" if (output =~ /started/)
      end # do loop for retrying...

      return result, (result == true) ? "" : "ERROR: Failed to start the backend process. Please check the system logs for more information"

    end #start

    def stop
      result, output = status
      return false, "ERROR: #{output}" if (result == false)

      output=%x(service #{SERVICE_NAME} stop 2>&1)
      result =$?.success?
      if (result == false)
        return false, "ERROR: #{output}"
      end

      return true, ""
    end

    def restart
      result, output = status
      return false, "ERROR: #{output}" if (result == false)

      # if the backend isnt running, just start it and quit.
      if (output =~ /stopped/) then
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