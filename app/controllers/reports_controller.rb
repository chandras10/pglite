class ReportsController < ApplicationController
 
  def login
  end

  def dash_inventory
    @deviceinfos = Deviceinfo.all
  end

  def tbl_inventory
    @deviceinfos = Deviceinfo.all
  end
 
  def dash_bw

    # Total (IN + OUTbytes) consumption per Server, per hour/day/month etc.
    # Key: Internal_Server_IP_address, Value: 'integer' array holding Mbytes consumed/hr/day/month etc.
    @hashTimeIntervalData = Hash.new

    #
    #  Per Server, Total INbytes and OUTBytes.
    # Key: Internal_Server_IP_address, Value: Array[INbytes, OUTbytes]
    @hashServerTotals = Hash.new

    #
    # Per Device, Total INbytes and OUTbytes
    # Key: Mobile Device MAC id, Value: Array[INbytes, OUTbytes]
    @hashDeviceTotals = Hash.new

    @IpstatRecs = Ipstat.select("strftime('%Y-%m-%d %H', timestamp) as time, 
                                destip as ip, deviceid as device, 
                                sum(inbytes) as inbytes, sum(outbytes) as outbytes").
                      # where("timestamp >= ?", 1.day.ago.strftime("%Y-%m-%d %H:%M:%S")).
                      where("timestamp >= ?", "2013-02-01").
                      group(:time, :destip, :deviceid).order(:destip)

    @IpstatRecs.each do |rec |

      # Update the Hashmap holding per hour/day/month stats for each server
       arrayData = @hashTimeIntervalData[rec['ip']]
       if arrayData.nil? then
          arrayData = @hashTimeIntervalData[rec['ip']] = Array.new(24, 0)
       end

       recTime = rec['time'].split[1].to_i
       arrayData[recTime] += (rec['inbytes'] + rec['outbytes'])

       # Update the Hashmap holding total in/out bytes counters for each server
       arrayData = @hashServerTotals[rec['ip']]
       if arrayData.nil? then
          arrayData = @hashServerTotals[rec['ip']] = Array.new(2, 0)
       end
       arrayData[0] += rec['inbytes']
       arrayData[1] += rec['outbytes']

       # Update the Hashmap holding total in/out bytes counters for each device (or client)
       arrayData = @hashDeviceTotals[rec['device']]
       if arrayData.nil? then
          arrayData = @hashDeviceTotals[rec['device']] = Array.new(2, 0)
       end
       arrayData[0] += rec['outbytes']  # for devices, OUT becomes IN and vice versa
       arrayData[1] += rec['inbytes']

    end # For each Ipstat record...

  end

  def dash_bw_server

    # Total (IN + OUTbytes) consumption per Port of the SELECTED server, per hour/day/month etc.
    # Key: Port, Value: 'integer' array holding Mbytes consumed/hr/day/month etc.
    @hashTimeIntervalData = Hash.new

    #
    #  Per Port, Total INbytes and OUTBytes.
    # Key: Internal_Server_IP_address, Value: Array[INbytes, OUTbytes]
    @hashPortTotals = Hash.new

    #
    # Per Device, Total INbytes and OUTbytes
    # Key: Mobile Device MAC id, Value: Array[INbytes, OUTbytes]
    @hashDeviceTotals = Hash.new

    @IpstatRecs= Ipstat.select("strftime('%Y-%m-%d %H', timestamp) as time, 
                                destport as destport, deviceid as device, 
                                sum(inbytes) as inbytes, sum(outbytes) as outbytes").
                      # where("timestamp >= ?", 1.day.ago.strftime("%Y-%m-%d %H:%M:%S")).
                      where("timestamp >= ? AND destip = ?", "2013-02-01", params[:server_ip]).
                      group(:time, :destport, :deviceid).order(:destport)

    @IpstatRecs.each do |rec |

      # Update the Hashmap holding per hour/day/month stats for each port of the SELECTED server
       arrayData = @hashTimeIntervalData[rec['destport']]
       if arrayData.nil? then
          arrayData = @hashTimeIntervalData[rec['destport']] = Array.new(24, 0)
       end

       recTime = rec['time'].split[1].to_i
       arrayData[recTime] += (rec['inbytes'] + rec['outbytes'])

       # Update the Hashmap holding total in/out bytes counters for each port of the SELECTED server
       arrayData = @hashPortTotals[rec['destport']]
       if arrayData.nil? then
          arrayData = @hashPortTotals[rec['destport']] = Array.new(2, 0)
       end
       arrayData[0] += rec['inbytes']
       arrayData[1] += rec['outbytes']

       # Update the Hashmap holding total in/out bytes counters for each device (or client)
       arrayData = @hashDeviceTotals[rec['device']]
       if arrayData.nil? then
          arrayData = @hashDeviceTotals[rec['device']] = Array.new(2, 0)
       end
       arrayData[0] += rec['outbytes']  # for devices, OUT becomes IN and vice versa
       arrayData[1] += rec['inbytes']

    end # For each Ipstat record...


  end

  def dash_snort

    @priorityLabels = Array["High", "Medium", "Low", "Very Low"]

    today = Time.mktime(Time.now.year, Time.now.month, Time.now.day-4).to_i # Epoch time of today at 00:00:00 hours
    snortAlertRecs = Alertdb.select("strftime('%Y-%m-%d %H', datetime(timestamp, 'unixepoch')) as time, 
                                priority as priority, sigid as sigid, message as message").
                        where("timestamp >= ?", today).
                        order(:priority, :sigid)

    @hashTimeIntervalData = Hash.new
    @hashSnortAlerts = Hash.new

    snortAlertRecs.each do |rec|
      rec_priority = @priorityLabels[rec['priority']-1]

      arrayData = @hashTimeIntervalData[rec_priority]
      if arrayData.nil? then
         arrayData = @hashTimeIntervalData[rec_priority] = Array.new(24, 0)
      end

      recTime = rec['time'].split[1].to_i
      arrayData[recTime] += 1

      arrayData = @hashSnortAlerts[rec['sigid']]
      if arrayData.nil? then
         arrayData = @hashSnortAlerts[rec['sigid']] = Array.new(3, 0)
         arrayData[1] = rec['message']
         arrayData[2] = rec_priority
      end
      arrayData[0] += 1

    end #for each SNORT alert record...
  end

  def tbl_snort
        @priorityLabels = Array["High", "Medium", "Low", "Very Low"]

        today = Time.mktime(Time.now.year, Time.now.month, Time.now.day-4).to_i # Epoch time of today at 00:00:00 hours
        @snortAlertRecs = Alertdb.select("strftime('%Y-%m-%d %H:%M:%S', datetime(timestamp, 'unixepoch')) as time, 
                                          priority as priority, sigid as sigid, message as message, 
                                          protocol as protocol, srcip as srcip, srcport as srcport, 
                                          destip as dstip, destport as dstport,
                                          srcmac as srcmac, dstmac as dstmac").
                                  where("timestamp >= ?", today).
                                  order(:priority, :sigid)

  end
end
