class ReportsController < ApplicationController
  before_filter :signed_in_user, only: [:dashboard, :dash_inventory, :tbl_inventory, 
                                        :dash_bw, :dash_bw_server,
                                        :dash_snort, :tbl_snort,
                                        :device_details, :tbl_vulnerability]

  def dashboard
    @deviceinfos = Deviceinfo.scoped

    tbl_vulnerability

    tbl_snort

    @license_info = Licenseinfo.first
  end

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

    @auth_src = Authsources.order('id')

  end 
 

  # Total bandwidth dashboard showing b/w usage
  def dash_bw

    # Total (IN + OUTbytes) consumption per Server/App, per hour/day/month etc.
    # Key: Server_IP_address/Application Name, Value: 'integer' array holding Mbytes consumed/hr/day/month etc.
    @hashTimeIntervalData = Hash.new

    #
    #  Per Server/App, Total INbytes and OUTBytes.
    # Key: Internal_Server_IP_address, Value: Array[INbytes, OUTbytes]
    @hashResourceTotals = Hash.new

    #
    # Per Device, Total INbytes and OUTbytes
    # Key: Mobile Device MAC id, Value: Array[INbytes, OUTbytes]
    @hashDeviceTotals = Hash.new

    #if there is no query string, then show the total bandwidth consumption.
    #else show specific data as pointed to by "type"
    #
    reportType = params['reportType'] || "total"

    if (reportType != "total")
       case reportType
          when "internalIP"
             dbQuery = Internalipstat.select("deviceid as device, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
          when "externalIP"
             dbQuery = Externalipstat.select("deviceid as device, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
          when "internalAPP"
             dbQuery = Internalresourcestat.select("deviceid as device, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
          when "externalAPP"
             dbQuery = Externalresourcestat.select("deviceid as device, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
       end
       dbQuery = createBandwidthStatsQuery(dbQuery, reportType)
       statRecordSets = [dbQuery]
    else # No query string means total bandwidth (internal IP + external IP)

       internalStatsQuery = Internalipstat.select("deviceid as device, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
       internalStatsQuery = createBandwidthStatsQuery(internalStatsQuery, "internalIP")
       externalStatsQuery = Externalipstat.select("deviceid as device, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
       externalStatsQuery = createBandwidthStatsQuery(externalStatsQuery, "externalIP")
 
       statRecordSets = [internalStatsQuery, externalStatsQuery]
    end

    statRecordSets.each do |recArray|
       recArray.each do |rec|
          # Update the Hashmap holding per hour/day/month stats for each server
          arrayData = @hashTimeIntervalData[rec['resource']]
          if arrayData.nil? then
             arrayData = @hashTimeIntervalData[rec['resource']] = Array.new(@numTimeSlots, 0)
          end

          arrayData[rec['time'].to_i] += (rec['inbytes'] + rec['outbytes'])

          # Update the Hashmap holding total in/out bytes counters for each server
          arrayData = @hashResourceTotals[rec['resource']]
          if arrayData.nil? then
             arrayData = @hashResourceTotals[rec['resource']] = Array.new(2, 0)
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

       end # For each stat record...
    end #statRecordSets

    case params['reportTime']
    when "past_day"
          # in case of past 24 hours, 
          currentHour = Time.now.strftime("%H.%M").to_f.ceil 
          @hashTimeIntervalData.each do |k, v|
             @hashTimeIntervalData[k] = v.rotate(currentHour+1)
          end
    end

  end # end of method

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

    reportType = params['reportType'] || "total"

    if (reportType != "total")
       case reportType
          when "internalIP"
             dbQuery = Internalipstat.select("deviceid as device, destport as service, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
             dbQuery = dbQuery.where("destip = ?", params['resource'])
          when "externalIP"
             dbQuery = Externalipstat.select("deviceid as device, destport as service, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
             dbQuery = dbQuery.where("destip = ?", params['resource'])
          when "internalAPP"
             dbQuery = Internalresourcestat.select("deviceid as device, appidinternal.appname as service, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
             dbQuery = dbQuery.where("appidinternal.appname = ?", params['resource'])
          when "externalAPP"
             dbQuery = Externalresourcestat.select("deviceid as device, appidexternal.appname as service, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
             dbQuery = dbQuery.where("appidexternal.appname = ?", params['resource'])
       end
       dbQuery = createBandwidthStatsQuery(dbQuery, reportType)
       dbQuery = dbQuery.group(:service)
       statRecordSets = [dbQuery]
    else # No query string means total bandwidth (internal IP + external IP)

       internalStatsQuery = Internalipstat.select("deviceid as device, destport as service, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
       internalStatsQuery = createBandwidthStatsQuery(internalStatsQuery, "internalIP")
       externalStatsQuery = Externalipstat.select("deviceid as device, destport as service, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
       externalStatsQuery = createBandwidthStatsQuery(externalStatsQuery, "externalIP")
 
       statRecordSets = [internalStatsQuery, externalStatsQuery]
    end

    statRecordSets.each do |recArray|

    recArray.each do |rec |

      # Update the Hashmap holding per hour/day/month stats for each port of the SELECTED server
       arrayData = @hashTimeIntervalData[rec['service']]
       if arrayData.nil? then
          arrayData = @hashTimeIntervalData[rec['service']] = Array.new(@numTimeSlots, 0)
       end

       arrayData[rec['time'].to_i] += (rec['inbytes'] + rec['outbytes'])

       # Update the Hashmap holding total in/out bytes counters for each port of the SELECTED server
       arrayData = @hashPortTotals[rec['service']]
       if arrayData.nil? then
          arrayData = @hashPortTotals[rec['service']] = Array.new(2, 0)
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

    case params['reportTime']
    when "past_day"
          # in case of past 24 hours, 
          currentHour = Time.now.strftime("%H.%M").to_f.ceil 
          @hashTimeIntervalData.each do |k, v|
             @hashTimeIntervalData[k] = v.rotate(currentHour+1)
          end
    end

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
    # Get the consumed bandwidth details (for last month) for this device
    params['reportTime'] = "past_month"
    dash_bw
    params['reportTime'] = nil

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

  #
  #-----------------------------------------------------------------------------
  #
  private

  def createBandwidthStatsQuery(dbQuery, reportType)

    #if there is no query string, then show the total bandwidth consumption.
    #else show specific data as pointed to by "type"
    #
    reportTime = params['reportTime'] || "today"

    fromDate = params['fromDate'] || Date.today.to_s
    begin
       toDate = params['toDate'] || (Date.parse(fromDate, "YYYY-MM-DD") + 1.day).to_s
    rescue
       toDate = Date.today.to_s # Just in case someone has meddled with the query string param and sent an invalid FROM date...
    end

    case reportType
    when "internalIP", "externalIP"
         dbQuery = dbQuery.joins(:deviceinfo).select("destip as resource").
                                                     group(:resource, :device).
                                                     order(:resource).scoped
    when "internalAPP"
         dbQuery = dbQuery.joins(:deviceinfo).joins(:appidinternal).select("appidinternal.appname as resource").
                                                     where("appidinternal.appid > 0").
                                                     group("appidinternal.appid", :device).
                                                     order("appidinternal.appid").scoped

    when "externalAPP"
         dbQuery = dbQuery.joins(:deviceinfo).joins(:appidexternal).select("appidexternal.appname as resource").
                                                     where("appidexternal.appid > 0").
                                                     group("appidexternal.appid", :device).
                                                     order("appidexternal.appid").scoped
    end

    case reportTime
    when "past_day"
         @timeSlot = "hour"
         @numTimeSlots = 24
         fromDate = 24.hours.ago
         toDate = Time.now
         dbQuery = dbQuery.select("date_part('hour', timestamp) as time").
                           where("timestamp > (CURRENT_TIMESTAMP - '24 hour'::interval)")
    when "past_week"
         fromDate = 7.days.ago
         toDate = Time.now
         @timeSlot = "day"
         @numTimeSlots = 7
         startingNum = ActiveRecord::Base.connection.select_value(ActiveRecord::Base.send(:sanitize_sql_array, 
                        ["select date_part('day', current_timestamp - '6 days'::interval)"]))

         dbQuery = dbQuery.select("date_part('day', timestamp) - #{startingNum} as time").
                           where("timestamp > (CURRENT_TIMESTAMP - '7 day'::interval)")
    when "past_month"
         fromDate = 1.month.ago
         toDate = Time.now
         @timeSlot = "week"
         @numTimeSlots = ((toDate - fromDate)/1.week).ceil + 1
         startingNum = ActiveRecord::Base.connection.select_value(ActiveRecord::Base.send(:sanitize_sql_array, 
                        ["select date_part('week', current_timestamp - '1 month'::interval)"]))

         dbQuery = dbQuery.select("date_part('week', timestamp) - #{startingNum} as time").
                           where("timestamp > (CURRENT_TIMESTAMP - '1 month'::interval)")
    when "date_range"
         begin
            fromDate = Date.parse(params['fromDate'], 'YYYY-MM-DD').to_time
         rescue
            fromDate = Date.today #if the incoming parameter is an invalid date format, then pick TODAY as the date!
            params['fromDate'] = fromDate.to_s
         end
         begin
            toDate = Date.parse(params['toDate'], 'YYYY-MM-DD').to_time + 1.day # end date should be inclusive in the range
         rescue
            # in case of parsing error, take FROMDATE + 1 as the end date...
            params['toDate'] = (Date.parse(params['fromDate'], 'YYYY-MM-DD') + 1.day).to_s
            toDate = (Date.parse(params['fromDate'], 'YYYY-MM-DD') + 1.day).to_time
         end

         numDays = ((toDate - fromDate)/1.day).round
         dbQuery = dbQuery.where("timestamp between '#{fromDate.strftime('%F')}' and '#{toDate.strftime('%F')}'")
         if numDays > 70 then
            @timeSlot = "month"
            @numTimeSlots = ((toDate - fromDate)/1.month).ceil + 1
            startingNum = ActiveRecord::Base.connection.select_value(ActiveRecord::Base.send(:sanitize_sql_array, 
                        ["select date_part('month', date '#{fromDate}')"]))

            dbQuery = dbQuery.select("date_part('month', timestamp) - #{startingNum} as time")
         elsif numDays > 31 then
            @timeSlot = "week"
            @numTimeSlots = ((toDate - fromDate)/1.week).ceil + 1
            startingNum = ActiveRecord::Base.connection.select_value(ActiveRecord::Base.send(:sanitize_sql_array, 
                        ["select date_part('week', date '#{fromDate}')"]))

            dbQuery = dbQuery.select("date_part('week', timestamp) - #{startingNum} as time")
         else
            @timeSlot = "day"
            @numTimeSlots = numDays
            startingNum = ActiveRecord::Base.connection.select_value(ActiveRecord::Base.send(:sanitize_sql_array, 
                        ["select date_part('day', date '#{fromDate}')"]))
            dbQuery = dbQuery.select("date_part('day', timestamp) - #{startingNum} as time")
         end
    else #default is TODAY
         fromDate = Time.mktime(Time.now.year, Time.now.month, Time.now.day)
         toDate = fromDate + 24.hours
         @timeSlot = "hour"
         @numTimeSlots = 24
         dbQuery = dbQuery.select("date_part('hour', timestamp) as time").
                           where("timestamp > date_trunc('day', CURRENT_TIMESTAMP)")
    end
    dbQuery = dbQuery.group(:time).order(:time)

    #add specific device to the query, if it exists
    dbQuery = dbQuery.where("deviceid = ?", params[:device]) if !params[:device].nil?

    return dbQuery
  end

end
