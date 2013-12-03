class PeregrineProcess
    
    PROCESS_NAME = "Peregrine"
    SERVICE_NAME = "pgguard"

    BACKEND_EXE = "/usr/local/bin/pgguard"
    BACKEND_EXE_ARGS = " -daemon"
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
        system("#{BACKEND_EXE} #{BACKEND_EXE_ARGS} 2>&1")
        result=$?.success?
        return false, "ERROR: Command: '#{BACKEND_EXE}' failed. Missing executable?" if (result == false)

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

      matchDef = /\D*(\d+)\D*/.match(output)
      if matchDef.nil? || matchDef[1].nil? then
        return false, "ERROR: Unable to find the process id (pid) for service - #{SERVICE_NAME}"
      end
     
      processID = matchDef[1].to_i
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