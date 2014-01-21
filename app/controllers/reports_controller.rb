class ReportsController < ApplicationController

  before_filter :signed_in_user, only: [:dash_inventory, :dash_inventory_bandwidth_stats, 
                                        :dash_bw, 
                                        :dash_snort, :tbl_snort,
                                        :device_details, :tbl_vulnerability,
                                        :dash_bw_world, :dash_bw_country]

  def dash_inventory
    @license_info = Licenseinfo.first
    @deviceinfos = Deviceinfo.scoped
  end

  def dash_inventory_i7_alert_count
    count = I7alert.where("timestamp >= date(CURRENT_TIMESTAMP)").count
    respond_to do |format|
       format.json { render json: count}
    end    
  end

  def dash_inventory_snort_alert_count
    count = Alertdb.where("timestamp >= date(CURRENT_TIMESTAMP)").count
    respond_to do |format|
       format.json { render json: count}
    end    
  end

  def dash_inventory_vuln_count
    count = DviVuln.count
    respond_to do |format|
       format.json { render json: count}
    end    
  end

  def dash_latest_i7_alerts
    alerts = I7alert.select('timestamp, i7alertdef.priority as priority, 
                              i7alertdef.description as description, i7alertclassdef.description as classtype, 
                              srcmac, dstmac').
                      joins('LEFT OUTER JOIN i7alertdef ON i7alertdef.id = i7alert.id 
                             LEFT OUTER JOIN i7alertclassdef ON i7alertclassdef.id = i7alertdef.classid').
                      where("i7alertdef.classid NOT in (#{Rails.configuration.i7alerts_ignore_classes.join('')})").
                      where("i7alertdef.active = true").
                      order("timestamp desc").limit(10)
    respond_to do |format|
      timeZone = Time.zone.name

       format.json {
          render json: alerts.map do |alert|
            {
        timestamp: alert.timestamp.in_time_zone(timeZone).strftime("%Y-%m-%d %H:%M"),
        priority: alert.priority,
        alerttype: alert.description,
        srcmac: alert.srcmac,
        dstmac: alert.dstmac
            }
          end
       }
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
    # We will for now, only show the statistics for BYOD devices. 
    #
    case reportType
    when "internalIP"
       @dbRecords = Internalipstat.joins(:deviceinfo).select("operatingsystem, destip as Internal_Server, sum(inbytes) as inbytes, sum(outbytes) as outbytes ").
                                   group("operatingsystem, destip").order("destip").
                                   where("deviceclass = 'MobileDevice'")
    when "byodIP"
       @dbRecords = Intincomingipstat.joins(:deviceinfo).select("operatingsystem, destip as Internal_Server, sum(inbytes) as inbytes, sum(outbytes) as outbytes ").
                                   group("operatingsystem, destip").order("destip").
                                   where("deviceclass = 'MobileDevice'")
    end # Which reportType?

    @dbRecords = setTimePeriod(@dbRecords)

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


end
