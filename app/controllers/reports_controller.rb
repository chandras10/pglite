class ReportsController < ApplicationController
  before_filter :signed_in_user, only: [:dash_inventory, :tbl_inventory, 
                                        :dash_bw, :dash_bw_server,
                                        :dash_snort, :tbl_snort,
                                        :device_details, :tbl_vulnerability]

  def dash_inventory
    @deviceinfos = Deviceinfo.scoped

    tbl_vulnerability

    tbl_snort
    
  end

  def tbl_inventory
    @deviceinfos = Deviceinfo.scoped

    columnName = params[:column]
    value = params[:value] 
    if (columnName.present?)
       case columnName
       when "auth_source"
          @deviceinfos = @deviceinfos.where("((auth_source is NULL) OR (auth_source = 0))")
       when "operatingsystem" && (!value.present? || value.empty?) 
          @deviceinfos = @deviceinfos.where("((operatingsystem is NULL) OR (operatingsystem = ''))")
       when "devicetype" && (!value.present? || value.empty?) 
          @deviceinfos = @deviceinfos.where("((devicetype is NULL) OR (devicetype = ''))")
       else
          @deviceinfos = @deviceinfos.where("#{columnName} = ?", value)
       end
    end
end
 
  # Total bandwidth dashboard showing b/w usage across all internal servers...
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

    today = Time.mktime(Time.now.year, Time.now.month, Time.now.day)
    #today = Time.mktime(2013, 03, 21) #TODO: DELETEME after testing

    if (params[:device].nil?) then
       @IpstatRecs = Ipstat.joins(:deviceinfo).
                            select("to_char(timestamp, 'YYYY-MM-DD HH') as time, 
                                    destip as ip, deviceid as device, 
                                    sum(inbytes) as inbytes, sum(outbytes) as outbytes").
                            #where("timestamp >= ?", 1.day.ago.strftime("%Y-%m-%d %H:%M:%S")).
                            where("timestamp >= ?", today).
                            group(:time, :destip, :deviceid).order(:destip)
    else 
       # all bandwidth records for a specific device
       @IpstatRecs = Ipstat.select("to_char(timestamp, 'YYYY-MM-DD HH') as time, 
                                    destip as ip, deviceid as device, 
                                    sum(inbytes) as inbytes, sum(outbytes) as outbytes").
                            #where("timestamp >= ? AND deviceid = ?", 1.day.ago.strftime("%Y-%m-%d %H:%M:%S"), params[:device]).
                            where("timestamp >= ? AND deviceid = ?", today, params[:device]). 
                            group(:time, :destip, :deviceid).order(:destip)
    end

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

       if (params[:device].nil?) then
          # Update the Hashmap holding total in/out bytes counters for each device (or client)
          arrayData = @hashDeviceTotals[rec['device']]
          if arrayData.nil? then
             arrayData = @hashDeviceTotals[rec['device']] = Array.new(2, 0)
          end
          arrayData[0] += rec['outbytes']  # for devices, OUT becomes IN and vice versa
          arrayData[1] += rec['inbytes']
       end

    end # For each Ipstat record...

  end

  # Bandwidth usage per server, for all ports and devices connected to this server
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

    today = Time.mktime(Time.now.year, Time.now.month, Time.now.day)
    #today = Time.mktime(2013, 03, 21) #TODO: DELETEME after testing

    @IpstatRecs= Ipstat.joins(:deviceinfo).
                        select("to_char(timestamp, 'YYYY-MM-DD HH') as time, 
                                destport as destport, deviceid as device, 
                                sum(inbytes) as inbytes, sum(outbytes) as outbytes").
                      #where("timestamp >= ? AND destip = ?", 1.day.ago.strftime("%Y-%m-%d %H:%M:%S"), params[:server_ip]).
                      where("timestamp >= ? AND destip = ?", today, params[:server_ip]).
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

  # SNORT Alerts dashboard
  def dash_snort

    @priorityLabels = Array["High", "Medium", "Low", "Very Low"]

    today = Time.mktime(Time.now.year, Time.now.month, Time.now.day)
    #today = Time.mktime(2013, 03, 21) #TODO: DELETEME after testing

    snortAlertRecs = Alertdb.joins(:deviceinfo).
                        select("to_char(timestamp, 'YYYY-MM-DD HH') as time, 
                                priority as priority, sigid as sigid, message as message").
                        where("timestamp >= ?", today).
                        order(:priority, :sigid)

    @hashTimeIntervalData = Hash.new
    @hashSnortAlerts = Hash.new

    snortAlertRecs.each do |rec|
      rec_priority = rec['priority'];

      arrayData = @hashTimeIntervalData[rec_priority]
      if arrayData.nil? then
         arrayData = @hashTimeIntervalData[rec_priority] = Array.new(24, 0)
      end

      hour = rec['time'].split[1] if !rec['time'].nil?
      recTime = if hour.nil? then 0 else hour.to_i end
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
        today = Time.mktime(Time.now.year, Time.now.month, Time.now.day)
        #today = Time.mktime(2013, 03, 18) #TODO: DELETEME after testing

        # Do we need filter the records based on selected device?
        macid = params[:device]
        if (macid.nil?) then
           @snortAlertRecs = Alertdb.select("to_char(timestamp, 'YYYY-MM-DD HH:MI:SS') as time, 
                                             priority as priority, sigid as sigid, message as message, 
                                             protocol as protocol, srcip as srcip, srcport as srcport, 
                                             destip as dstip, destport as dstport,
                                             srcmac as srcmac, dstmac as dstmac").
                                     #where("timestamp >= ?", today).
                                     order(:priority, :sigid)
        else
           @snortAlertRecs = Alertdb.select("to_char(timestamp, 'YYYY-MM-DD HH:MI:SS') as time, 
                                             priority as priority, sigid as sigid, message as message, 
                                             protocol as protocol, srcip as srcip, srcport as srcport, 
                                             destip as dstip, destport as dstport,
                                             srcmac as srcmac, dstmac as dstmac").
                                     #where("timestamp >= ? AND (srcmac = ? OR dstmac = ?)", today, macid, macid).
                                     where("(srcmac = ? OR dstmac = ?)", macid, macid).
                                     order(:priority, :sigid)
        end

  end

  def device_details
    macid = params[:device]
    if (macid.nil? || macid.empty?) then return end
   
    @devicedetails = Deviceinfo.find(:all, :conditions => ["macid = ?", macid])
   
    #We get an array of database records from find(). In the ideal world, there should only be one deviceinfo record for a given MAC id.
    if (!@devicedetails.nil?) then
      @devicedetails = @devicedetails.first
    end

    this_year = Time.mktime(Time.now.year, 01, 01) 
    #find all the Snort alerts
    @snortAlertRecs = Alertdb.select("timestamp as time, 
                                      priority as priority, sigid as sigid, message as message, 
                                      protocol as protocol, srcip as srcip, srcport as srcport, 
                                      destip as dstip, destport as dstport,
                                      srcmac as srcmac, dstmac as dstmac").
                              where("timestamp >= ? AND (srcmac = ? OR dstmac = ?)", this_year, macid, macid).
                              order(:priority, :sigid)

    #
    # Create a hashmap of  record counts, grouped by "MONTH" and then grouped by "PRIORITY".
    # NOTE: This wonderful ruby code (it is legible code) is credited to this 
    # link: http://stackoverflow.com/questions/5639921/group-a-ruby-array-of-dates-by-month-and-year-into-a-hash
    #
    @hashSnortAlerts = Hash[ @snortAlertRecs.group_by { |a| a["time"][5..6] }.map { |month, recs|
                              [month, recs.group_by {|a| a["priority"] } ]
                             }
                           ]

    
    #
    # Get all the CVE notices for the given device
    cveAlertRecs = DviVuln.joins(:vulnerability).
                            where("mac = ?", macid).select("mac, vuln_id, vulnerability.cvss_score, vulnerability.last_modify_date as date")


    #
    #TODO: Right now, we are grouping by MONTH only. We will have to consider YEAR as well.
    @hashCveAlerts = cveAlertRecs.group_by { |a| a["date"][5..6]  }

    #
    # Get the consumed bandwidth details for this device
    dash_bw

    #
    # Get all the apps for this device
    @appList = Browserversion.select("browsername as app, version")
                             .where("macid = ?", macid)
                             .order(:browsername)
  
  end #device_details 

  def tbl_vulnerability
    #
    # Get all the CVE notices

    # Do we need filter the records based on selected device?
    macid = params[:device]
    if (macid.nil?) then
       @cveAlertRecs = DviVuln.joins(:vulnerability).
                               select("mac, vuln_id, vulnerability.cvss_score as score, vulnerability.last_modify_date as date, summary").
                               order(:score)
    else
       @cveAlertRecs = DviVuln.joins(:vulnerability).
                               where("mac = ?", macid).
                               select("mac, vuln_id, vulnerability.cvss_score as score, vulnerability.last_modify_date as date, summary").
                               order(:score)
    end
  end
end
