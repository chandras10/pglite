class BandwidthDatatable
  include DatatablesHelper
  include ReportsHelper
  include ActionView::Helpers::NumberHelper  #using the number_to_human_size function call...

  delegate :params, :h, :link_to,  to: :@view

  def initialize(view, dbTable, destIDColumn)
    @view = view
    @dbTable = dbTable.constantize
    @destIDColumn = destIDColumn
  end

  def as_json(options = {})
    case params["dataType"]
    when "top"
      limit = 10 # Hardcoding to get top 10 destinations only!

      # For each of the top N, create a value array. The array size is same as number of time slots (hours/days/weeks)
      # and then plunk the bandwidth (IN+OUT bytes) into the correct bucket.
      dests = Hash.new
      topDestinations(limit).each do |rec|
        dests[rec.key] = Array.new(@numTimeSlots, 0) if dests[rec.key].nil?
        timeSlot = rec.time.to_i
        dests[rec.key][timeSlot] += rec.totalbw.to_i if (timeSlot > 0 and timeSlot < @numTimeSlots)
      end

      return {
        numvlines: @numTimeSlots - 1,
        labels: bandwidthGraphTimeSlotLabels,
        keys: dests.keys,
        values: dests.values,
        title: "Bandwidth #{bandwidth_label}"
      }

    when "dst"
      dbRecords = getDestinations
    when "src"
      dbRecords = getSources
    end
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: @dbTable.count,
      iTotalDisplayRecords: dbRecords.total_entries,
      aaData: data
    }
  end

protected

  def data
    case params["dataType"]
    when "dst"
      paramHash = {}
      paramHash[:action] = "dash_bw_server"
      paramHash[:controller] = "reports"
      paramHash[:reportType] = params[:reportType]
      if params.has_key?(:reportTime) then
        paramHash[:reportTime] = params[:reportTime]
        if params[:reportTime] == "date_range" then
          paramHash[:fromDate] = params[:fromDate]
          paramHash[:toDate] = params[:toDate]
       end
      end

      dbRecords = getDestinations
      dbRecords.map do |rec|
        {
          key: link_to(rec.key, paramHash.merge({:resource=> rec.key})),
          sent: h(number_to_human_size rec.sent),
          recd: h(number_to_human_size rec.recd),
          total: h(number_to_human_size rec.total)
        }
      end
    when "src"
      devices = Deviceinfo.all
      dbRecords = getSources
      dbRecords.map do |rec|
        # For each record, replace the macid with either username or ip_address, if present.
        device = devices.find { |d| d.macid == rec.key }
        key = rec.key
        if !device.nil?
          if !device.username.nil? && !device.username.empty?
             key = device.username
          elsif !device.ipaddr.nil? && !device.ipaddr.empty?
             key = device.ipaddr
          else
             key = device.macid
          end
        end # deviceInfo record found?
        {
          key: link_to(key, :action=> "device_details", :controller=> "reports", :device => rec.key),
          sent: h(number_to_human_size rec.sent),
          recd: h(number_to_human_size rec.recd),
          total: h(number_to_human_size rec.total)
        }
      end #foreach database record...
    end
  end

  def getDestinations
    return getDestinationsWithConditions(nil)
  end

  def getDestinationsWithConditions(initialQuery)
    defaultQuery = @dbTable.select("#{@destIDColumn} as key").group("#{@destIDColumn}")
    defaultQuery = defaultQuery.where("#{@destIDColumn} ILIKE :search", search: "%#{params[:sSearch]}%") if (params[:sSearch].present? && !params[:sSearch].empty?)

    records = initialQuery || defaultQuery
    records = records.select("sum(inbytes) as sent, sum(outbytes) as recd, sum(inbytes) + sum(outbytes) as total")
    records = setTimePeriod(records)
    records = records.order("#{sort_column} #{sort_direction}")
    records = records.page(page).per_page(per_page)
    records
  end

  def getSources
    records = @dbTable.select("deviceid as key, sum(inbytes) as sent, sum(outbytes) as recd, sum(inbytes) + sum(outbytes) as total").
                       group("deviceid")
    records = setTimePeriod(records)
    records = records.order("#{sort_column} #{sort_direction}")
    records = records.page(page).per_page(per_page)
    records
  end

  def topDestinations(n)
    topDestinationsWithConditions(nil, n)
  end

  def topDestinationsWithConditions(initialQuery, n)
    #
    # First get the top N destinations consuming the bandwidth (IN + OUT bytes)
    #
    topDests = @dbTable.select("#{@destIDColumn} as key, sum(inbytes) + sum(outbytes) as totalBW").group(@destIDColumn).order("totalBW desc").limit(n)
    topDests = setTimePeriod(topDests)

    #
    # Once you have the top N destinations, then do a database query using this list. But now, get the bandwidth values
    # for each time period (hours/days/weeks) depending on the user selected time period
    #
    destList = Array.new(n)
    topDests.each_with_index do |dest, i|
      destList[i] = dest.key
    end
    records = initialQuery || @dbTable.select("#{@destIDColumn} as key").group("#{@destIDColumn}")
    records = records.select("sum(inbytes) + sum(outbytes) as totalBW").order("totalBW desc")
    records = selectTimeIntervals(records)
    records = records.where(@destIDColumn.to_sym => destList) # Get the database records for only the top N dests
    records
  end

  def columns
      %w[key sent recd total]
  end

  def sort_column
    columns[params[:iSortCol_0].to_i]
  end

  def setTimePeriod(dbQuery)
    reportTime = params['reportTime'] || "today"

    fromDate = params['fromDate'] || Date.today.to_s
    begin
       toDate = params['toDate'] || (Date.parse(fromDate, "YYYY-MM-DD") + 1.day).to_s
    rescue
       toDate = Date.today.to_s # Just in case someone has meddled with the query string param and sent an invalid FROM date...
    end

    case reportTime
    when "past_hour"
         dbQuery = dbQuery.where("timestamp > (CURRENT_TIMESTAMP - '1 hour'::interval)")         
    when "past_day"
         dbQuery = dbQuery.where("timestamp > (CURRENT_TIMESTAMP - '24 hour'::interval)")
    when "past_week"
         dbQuery = dbQuery.where("timestamp > (CURRENT_TIMESTAMP - '7 day'::interval)")
    when "past_month"
         dbQuery = dbQuery.where("timestamp > (CURRENT_TIMESTAMP - '1 month'::interval)")
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

         dbQuery = dbQuery.where("timestamp between '#{fromDate.strftime('%F')}' and '#{toDate.strftime('%F')}'")
    else #default is TODAY
         dbQuery = dbQuery.where("timestamp >= date_trunc('day', CURRENT_TIMESTAMP)")
    end

    return dbQuery

  end

  def selectTimeIntervals(dbQuery)

    if dbQuery.nil?
       return
    end

    dbQuery = setTimePeriod(dbQuery)

    reportTime = params['reportTime'] || "today"

    fromDate = params['fromDate'] || Date.today.to_s
    begin
       toDate = params['toDate'] || (Date.parse(fromDate, "YYYY-MM-DD") + 1.day).to_s
    rescue
       toDate = Date.today.to_s # Just in case someone has meddled with the query string param and sent an invalid FROM date...
    end

    case reportTime
    when "past_hour"
         @timeSlot = "minute"
         @numTimeSlots = 5
         fromDate = 1.hour.ago
         toDate = Time.now
         dbQuery = dbQuery.select("MOD(cast(date_part('minute', timestamp) as INT), #{@numTimeSlots}) as time")
    when "past_day"
         @timeSlot = "hour"
         @numTimeSlots = 24
         fromDate = 24.hours.ago
         toDate = Time.now
         dbQuery = dbQuery.select("date_part('hour', timestamp) as time")
    when "past_week"
         fromDate = 7.days.ago
         toDate = Time.now
         @timeSlot = "day"
         @numTimeSlots = 7
         dbQuery = dbQuery.select("EXTRACT(day from timestamp - (current_timestamp - '7 day'::interval)) as time")
    when "past_month"
         fromDate = 1.month.ago
         toDate = Time.now
         @timeSlot = "week"
         @numTimeSlots = ((toDate - fromDate)/1.week).ceil + 1
         startingNum = ActiveRecord::Base.connection.select_value(ActiveRecord::Base.send(:sanitize_sql_array, 
                        ["select date_part('week', current_timestamp - '1 month'::interval)"]))

         dbQuery = dbQuery.select("date_part('week', timestamp) - #{startingNum} as time")
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
            dbQuery = dbQuery.select("EXTRACT(day from timestamp - date '#{fromDate}') as time")
         end
    else #default is TODAY
         fromDate = Time.mktime(Time.now.year, Time.now.month, Time.now.day)
         toDate = fromDate + 24.hours
         @timeSlot = "hour"
         @numTimeSlots = 24

         dbQuery = dbQuery.select("date_part('hour', timestamp) as time")
    end

    dbQuery = dbQuery.group(:time).order(:time)

    return dbQuery

  end


end