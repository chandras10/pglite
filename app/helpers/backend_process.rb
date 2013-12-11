class String
  def processID?
    matchDef = self.match(/\D+(\d+).*/)
    if matchDef.nil? || matchDef[1].nil? 
       return false
    end
    Float(matchDef[1]) != nil rescue false
  end
end


class BackendProcess
  NUM_RETRIES = 3 # Number of times to try doing something before return error
  SLEEP_INTERVAL = 5 # in seconds

  def initialize
    @processName = "Unknown"
    @serviceName = "Unknown"
    @exeName = ""
    @exeArgs = ""
  end

  def start
    return false, "Start method not implemented for this process."
  end

  def stop
    return false, "Stop method not implemented for this process."
  end

  def restart
    return false, "Restart method not implemented for this process."
  end

  def toggle
    result, output = status
    return (result == true) ? stop : start
  end

  def status
    return false, "Status method not implemented for this process."
  end

  def name
    return @processName
  end

  def id
    return @serviceName
  end

end

#
# This class is meant for backend processes which are started from the command line as is. 
# That is, they do not have a System V init script and hence cannot use service start/stop command.
#
class SimpleProcess < BackendProcess
  
  def start
    # Start the backend application. This function will make a few attempts to start the process before giving up.
    #
    result = false
    output = ""
    systemCmd = "#{@exeName} #{@exeArgs}"

    NUM_RETRIES.times do
      output = system("#{systemCmd} 2>&1")
      result=$?.success?
      return false, "'#{systemCmd}' failed." if (result == false)

      sleep(SLEEP_INTERVAL)
      
      result, output  = status
      return false, output + ' Failed to start the process.' if (result == false)      
        
    end # do loop for retrying...

    return result, (result == true) ? output : "'#{systemCmd}' failed."
  end #start

  def stop
    # Check if the process is running before attempting to stop it.
    result, output = status
    return false, "ERROR: '#{@processName}' is currently not running." if  !output.processID?
     
    matchDef = output.match(/\D*(\d+).*/)
    output=system("kill -s TERM #{matchDef[1]} 2>&1")
    result =$?.success?
    return false, "Unable to stop '#{@processName}'. Error: #{output}" if (result == false)
        
    # In some cases, the process takes a long to exit or might be hanging. Issue a SIGKILL just to ensure the process does indeed terminate.
    sleep(SLEEP_INTERVAL)
    system("kill -9 #{matchDef[1]}") 

    return true, "'#{@processName}' has been stopped."

  end #stop

  def restart
  	#if it is not running, then start the process and exit. 
    result, output = status
    return start if (result == false) || !output.processID?

    #else, stop it first and then start it again!
    result, output = stop
    return result, output if (result == false)
     
    return start
  end

  def status
    output = %x(pidof #{@exeName} 2>&1)
    result =$?.success?
    if (result == false) 
      output = "'#{@processName}' is not running."
    else
      output = "'#{@processName}' is running. ProcessID: #{output}."
    end

    return result, output
  end


end # end of SimpleProcess class

#
# This class encompasses processes which have System V init scripts.
# In other words, we have to use service <process> start/stop/status
#
class ServiceProcess < BackendProcess
   
  def start
    # Start the backend application. This function will make a few attempts to start the process before giving up.
    #
    result = false
    output = ""
    NUM_RETRIES.times do 
      output = system("service #{@serviceName} start 2>&1")
      result=$?.success?
      return false, "Failed to start service - '#{@serviceName}'." if (result == false)

      sleep(SLEEP_INTERVAL)
      
      result, output  = status
      return true, output if (output =~ /running/)
    end # do loop for retrying...

    return result, "Failed to start service - '#{@serviceName}'. Please check the system logs for more information."

  end #start

  def stop
    result, output = status
    return false, output if (result == false)

    result, output = system("service #{@serviceName} stop 2>&1")
    return false, output if (result == false)
    
    return true, "Service: '#{@serviceName}' has been stopped."
  end

  def restart
    result, output = status
    return false, output if (result == false)

    return start if (output =~ /stopped/)

    result, output = stop
    return result, output if (result == false)
     
    return start
  end

  def status
    output = %x(service #{@serviceName} status 2>&1)
    result =$?.success?
    return result, output if (result == false)
    
    if (output =~ /running/) then
      return true, "Service: '#{@serviceName}' is running."
    else
      return true, "Service: '#{@serviceName}' is stopped."
    end

  end

end # end of ServiceProcess class