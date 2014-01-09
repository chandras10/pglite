class ReportsController < ApplicationController

  before_filter :signed_in_user, only: [:dash_inventory, :dash_inventory_bandwidth_stats, 
                                        :dash_bw, :dash_bw_server,
                                        :dash_snort, :tbl_snort,
                                        :device_details, :tbl_vulnerability,
                                        :dash_bw_world, :dash_bw_country]

  def dash_inventory
    @license_info = Licenseinfo.first
    @deviceinfos = Deviceinfo.scoped
  end

  def dash_inventory_asset_count
    assetCount = Internalipstat.select(:destip).uniq.group(:destip).having('sum(inbytes) > 0').length
    respond_to do |format|
       format.json { render json: assetCount}
    end    
  end

  def dash_inventory_alert_count
    cnt = Alertdb.count
    respond_to do |format|
       format.json { render json: cnt}
    end    
  end

  def dash_inventory_vuln_count
    cnt = DviVuln.count
    respond_to do |format|
       format.json { render json: cnt}
    end    
  end

  def dash_inventory_bandwidth_stats
    internalIPStats = Internalipstat.joins(:deviceinfo).select('deviceclass, sum(inbytes) as inbytes, sum(outbytes) as outbytes').
                                      group(:deviceclass).where("timestamp > (CURRENT_TIMESTAMP - '1 month'::interval)")
    externalIPStats = Externalipstat.joins(:deviceinfo).select('deviceclass, sum(inbytes) as inbytes, sum(outbytes) as outbytes').
                                      group(:deviceclass).where("timestamp > (CURRENT_TIMESTAMP - '1 month'::interval)")

    hashIPstats = Hash.new
    internalIPStats.each do |rec|
       hashIPstats[rec.deviceclass] = [rec.inbytes.to_i, rec.outbytes.to_i]
    end

    externalIPStats.each do |rec|
      #
      # There could be a new deviceclass in External stat table but missing from InternalIP stat. 
      # Create a empty entry to fix 500 Internal error because of nil.
      #
      if hashIPstats[rec.deviceclass].nil? then
          hashIPstats[rec.deviceclass] = [0, 0]
      end
      hashIPstats[rec.deviceclass]  << rec.inbytes.to_i
       hashIPstats[rec.deviceclass] << rec.outbytes.to_i
    end

    respond_to do |format|
       format.json { render json: hashIPstats}
    end
  end

  # Total bandwidth dashboard showing b/w usage
  def dash_bw

    statCounters = {
                     "internalIP"       => BandwidthDatatable.new(view_context, "Internalipstat", "destip"),
                     "externalIP"       => BandwidthDatatable.new(view_context, "Externalipstat", "destip"),
                     "byodIP"           => BandwidthDatatable.new(view_context, "Intincomingipstat", "destip"),
                     "internalAPP"      => BandwidthResourceDatatable.new(view_context, "Internalresourcestat", "appid", "appidinternal", "appname"),
                     "externalAPP"      => BandwidthResourceDatatable.new(view_context, "Externalresourcestat", "appid", "appidexternal", "appname"),
                     "external_urlcat"  => BandwidthResourceDatatable.new(view_context, "Urlcatstat", "id", "urlcatid", "name"),
                     "external_hlurlcat"=> BandwidthResourceDatatable.new(view_context, "Hlurlcatstat", "id", "hlurlcatid", "name")
                   }

    set_IPstatTypes_constants
    set_timeLine_constants

    #Set some defaults, in order to avoid crashes
    params['reportType'] = "internalIP" if !params['reportType'].present?
    params['reportTime'] = "today" if !params['reportTime'].present?
    params['dataType'] = "dst" if !params['dataType'].present? # return the list of servers

    respond_to do |format|
       format.html
       format.json { render json: statCounters[params['reportType']]}
    end

  end # end of method

  # Bandwidth usage per server, for all ports and devices connected to this server
  def dash_bw_server

    set_timeLine_constants


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

    reportType = params['reportType'] || "internalIP"
    reportType = "internalIP" if (!reportType.nil? && reportType == "deviceAPP" )

    case reportType
      when "internalIP"
        dbQuery = Internalipstat.select("deviceid as client, destport as service, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
        dbQuery = dbQuery.where("destip = ?", params['resource'])
      when "externalIP"
        dbQuery = Externalipstat.select("deviceid as client, destport as service, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
        dbQuery = dbQuery.where("destip = ?", params['resource'])
      when "byodIP"
        dbQuery = Intincomingipstat.select("deviceid as client, destport as service, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
        dbQuery = dbQuery.where("destip = ?", params['resource'])
      when "internalAPP"
        dbQuery = Internalresourcestat.select("deviceid as client, appidinternal.appname as service, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
        dbQuery = dbQuery.where("appidinternal.appname = ?", params['resource'])
      when "externalAPP"
        dbQuery = Externalresourcestat.select("deviceid as client, appidexternal.appname as service, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
        dbQuery = dbQuery.where("appidexternal.appname = ?", params['resource'])
      when "external_urlcat"
        dbQuery = Urlcatstat.joins(:urlcatid).select("deviceid as client, urlcatid.name as service, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
        dbQuery = dbQuery.where("urlcatid.name = ?", params['resource'])
      when "external_hlurlcat"
        dbQuery = Hlurlcatstat.joins(:hlurlcatid).select("deviceid as client, hlurlcatid.name as service, sum(inbytes) as inbytes, sum(outbytes) as outbytes")
        dbQuery = dbQuery.where("hlurlcatid.name = ?", params['resource'])
    end
    dbQuery = createBandwidthStatsQuery(dbQuery, reportType)
    dbQuery = dbQuery.group(:service)

    dbQuery.each do |rec |

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
       arrayData[1] += rec['inbytes']
       arrayData[0] += rec['outbytes']

       # Update the Hashmap holding total in/out bytes counters for each device (or client)
       clientData = @hashDeviceTotals[rec['client']]
       if clientData.nil? then
          clientData = @hashDeviceTotals[rec['client']] =  {:user => rec['user'], :ipaddress => rec['ipaddress'], :totals => Array.new(2, 0) }
       end
       clientData[:totals][0] += rec['inbytes']  
       clientData[:totals][1] += rec['outbytes']

    end # For each stat record...

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

    set_IPstatTypes_constants
    set_timeLine_constants


    dbQuery = Alertdb.select("priority as priority, sigid as sigid, message as message, count(*) as cnt").
                                         group(:priority, :sigid, :message).order(:priority, :sigid)
    dbQuery = selectTimeIntervals(dbQuery)
    #add specific device to the query, if it exists
    if (params[:device].present?)
       dbQuery = dbQuery.where("srcmac = ? OR dstmac = ?", params[:device], params[:device])
    else
       dbQuery = dbQuery.joins(:deviceinfo)
    end

    @hashSnortTimeIntervalData = Hash.new
    @hashSnortAlerts = Hash.new

    dbQuery.each do |rec|
      rec_priority = rec['priority'];

      arrayData = @hashSnortTimeIntervalData[rec_priority]
      if arrayData.nil? then
         arrayData = @hashSnortTimeIntervalData[rec_priority] = Array.new(@numTimeSlots, 0)
      end

      arrayData[rec['time'].to_i] += rec['cnt'].to_i

      arrayData = @hashSnortAlerts[rec['sigid']]
      if arrayData.nil? then
         arrayData = @hashSnortAlerts[rec['sigid']] = Array.new(3, 0)
         arrayData[1] = rec['message']
         arrayData[2] = rec_priority
      end
      arrayData[0] += rec['cnt'].to_i

    end #for each SNORT alert record...
  end

  
  def tbl_snort

    set_timeLine_constants
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: SnortAlertsDatatable.new(view_context)}
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
  end #device_details 

  def device_i7alerts
    respond_to do |format|
      format.json { render json: DeviceRecordsDatatable.new(view_context, "i7alerts")}
    end
  end

  def device_snortalerts
    respond_to do |format|
      format.json { render json: DeviceRecordsDatatable.new(view_context, "snort")}
    end
  end

  def device_vulnerabilities
    respond_to do |format|
      format.json { render json: DeviceRecordsDatatable.new(view_context, "vuln")}
    end
  end

  def device_apps
    respond_to do |format|
      format.json { render json: DeviceRecordsDatatable.new(view_context, "apps")}
    end
  end

  def device_bandwidth_usage
    respond_to do |format|
      format.json { render json: DeviceRecordsDatatable.new(view_context, "bandwidth")}
    end
  end

  def tbl_vulnerability

    dbQuery = DviVuln

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: DeviceVulnerabilitiesDatatable.new(view_context)}
    end
  end

  def dash_bw_pivottable

    set_timeLine_constants
    @availableBandwidthReportTypes = { 
                                        "internalIP"  => "Internal Servers",
                                        "byodIP"   => "BYOD Servers"
                                      }

    reportType = params['reportType'] || "internalIP"

    #
    # Get the WHERE clause for time-based query and append it to the SQL below. 
    # I had to do some regular expression gimmick/hack to extract only the WHERE clause because
    # I am employing 'find_by_sql' for the DB queries. (Not efficient but works...)
    #
    dbQuery = Internalipstat
    dbQuery = setTimePeriod(dbQuery)
    timeQueryString = dbQuery.to_sql.scan(/SELECT (.*) FROM .* WHERE\s+\((.*)\).*/i)

    #
    # Limiting this query to 10 DISTINCT ports and also to a maximum of 2000 database records only. Else, the client browser will hang...
    #
    case reportType
    when "internalIP"
       @dbRecords = Internalipstat.find_by_sql("with top_ports as 
                                               (SELECT destport, sum(inbytes)+sum(outbytes) as total_bw from internalipstat
                                                where #{timeQueryString[0][1]} 
                                                group by destport order by total_bw desc LIMIT 10),
                                                ports as (select destport from top_ports) 
                                                select d.username, d.groupname, d.auth_source, d.operatingsystem, d.deviceclass, destip as Internal_Server, destport as Port, 
                                                       sum(inbytes) as inbytes, sum(outbytes) as outbytes  from internalipstat stat, deviceinfo d 
                                                where destport in (select destport from ports) and d.macid = stat.deviceid and #{timeQueryString[0][1]}
                                                group by d.username, d.groupname, d.auth_source, d.operatingsystem, d.deviceclass, destip, destport order by destip, destport
                                                LIMIT 2000")
    when "byodIP"
       @dbRecords = Intincomingipstat.find_by_sql("with top_ports as 
                                                  (SELECT destport, sum(inbytes)+sum(outbytes) as total_bw from intincomingipstat 
                                                   where #{timeQueryString[0][1]} 
                                                  group by destport order by total_bw desc LIMIT 10), 
                                                  ports as (select destport from top_ports) 
                                                  select d.username, d.groupname, d.auth_source, d.operatingsystem, d.deviceclass, destip as Internal_Server, destport as Port, 
                                                         sum(inbytes) as inbytes, sum(outbytes) as outbytes  from intincomingipstat stat, deviceinfo d 
                                                  where destport in (select destport from ports) and d.macid = stat.deviceid and #{timeQueryString[0][1]}
                                                  group by d.username, d.groupname, d.auth_source, d.operatingsystem, d.deviceclass, destip, destport order by destip, destport
                                                  LIMIT 2000")
    end # Which reportType?
  end
  
  def dash_bw_world
    set_timeLine_constants

    @countryCodes = IsoCountryCodes.for_select
    bwLimit = 0
    @dbRecords = Externalipstat.select('cc, sum(inbytes) as download, sum(outbytes) as upload').
                           having('sum(inbytes) > ? or sum(outbytes) > ?', bwLimit, bwLimit).
                           group('cc').
                           order('cc')
    @dbRecords = setTimePeriod(@dbRecords)

    @totalBWPerCountry = Hash.new
    @dbRecords.each do |r|
       code = (r.cc.nil? ? "--" : r.cc.downcase)
       @totalBWPerCountry[code] = r.download.to_i + r.upload.to_i
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @totalBWPerCountry}
    end
  end

  def dash_bw_country
    @dbRecords = Externalipstat.select('count(distinct destip) as serverCount, sum(inbytes) as download, sum(outbytes) as upload, sum(inbytes)+sum(outbytes) as total').
                                where("cc = ?", params[:country])
    @dbRecords = setTimePeriod(@dbRecords)

    respond_to do |format|
       format.json { render json: @dbRecords }
    end
  end

  def dash_bw_country_details
    respond_to do |format|
      format.json { render json: BandwidthByCountryDatatable.new(view_context)}
    end
  end

  def resolve_hosts
    dnsResolver = Resolv::DNS.new
    ipList = params['ipList'].split(',') if !params['ipList'].present? || [];

    hostNames = []
    ipList.each do |ip|
      #
      # Check if we have a IP address or a URL. Resolve only IPv4 addresses...
      #
      if (ip.match(/\d+{,3}\.\d+{,3}\.\d+{,3}\.\d+{,3}$/)) then
         begin
           hostNames << dnsResolver.getname(ip).to_s
         rescue
           hostNames << ip #In case of any exceptions, just return the IP itself ...
         end
      else
         hostNames << ip
      end
    end
    respond_to do |format|
      format.json { render json: hostNames}
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

    case reportType
    when "internalIP", "externalIP", "byodIP"
         dbQuery = dbQuery.joins(:deviceinfo).select("destip as resource, deviceinfo.username as user, deviceinfo.ipaddr as ipaddress").
                                                     group(:resource, 'deviceinfo.username', 'deviceinfo.ipaddr', :client).
                                                     order(:resource).scoped
    when "internalAPP"
         dbQuery = dbQuery.joins(:deviceinfo).joins(:appidinternal).select("appidinternal.appname as resource, deviceinfo.username as user, deviceinfo.ipaddr as ipaddress").
                                                     where("appidinternal.appid > 0").
                                                     group("appidinternal.appid", 'deviceinfo.username', 'deviceinfo.ipaddr', :client).
                                                     order("appidinternal.appid").scoped

    when "externalAPP"
         dbQuery = dbQuery.joins(:deviceinfo).joins(:appidexternal).select("appidexternal.appname as resource, deviceinfo.username as user, deviceinfo.ipaddr as ipaddress").
                                                     where("appidexternal.appid > 0").
                                                     group("appidexternal.appid", 'deviceinfo.username', 'deviceinfo.ipaddr', :client).
                                                     order("appidexternal.appid").scoped
    when "external_urlcat"
         dbQuery = dbQuery.joins(:deviceinfo).joins(:urlcatid).select("urlcatid.name as resource, deviceinfo.username as user, deviceinfo.ipaddr as ipaddress").
                                                     group("urlcatid.id", 'deviceinfo.username', 'deviceinfo.ipaddr', :client).
                                                     order("urlcatid.name").scoped      
    when "external_hlurlcat"
         dbQuery = dbQuery.joins(:deviceinfo).joins(:hlurlcatid).select("hlurlcatid.name as resource, deviceinfo.username as user, deviceinfo.ipaddr as ipaddress").
                                                     group("hlurlcatid.id", 'deviceinfo.username', 'deviceinfo.ipaddr', :client).
                                                     order("hlurlcatid.name").scoped      
    end

    dbQuery = selectTimeIntervals(dbQuery)

    #add specific device to the query, if it exists
    dbQuery = dbQuery.where("deviceid = ?", params[:device]) if !params[:device].nil?

    return dbQuery
  end


end
