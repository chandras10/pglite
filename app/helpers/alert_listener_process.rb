require 'backend_process'

class AlertListenerProcess < SimpleProcess

  def initialize
    @processName = "Alert Listener"
    @serviceName = "alertlistener"
    @exeName = "/usr/local/bin/alertlistener"
    @exeArgs = " /usr/local/etc/alertlistener/PGAlertListnerConfig.xml"
  end

end
