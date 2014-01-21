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
    if (params["dataType"] == "top") then
      limit = 10 # Hardcoding to get top 10 destinations only!

      # For each of the top N, create a value array. The array size is same as number of time slots (hours/days/weeks)
      # and then plunk the bandwidth (IN+OUT bytes) into the correct bucket.
      dests = Hash.new
      if !params['resource'].present? then
        topDests = topDestinations(limit)
      else
        topDests = topDestPorts(limit)
      end

      if !topDests.nil? then
        topDests.each do |rec|
          dests[rec.key] = Array.new(@numTimeSlots, 0) if dests[rec.key].nil?
          timeSlot = rec.time.to_i
          dests[rec.key][timeSlot] += rec.totalbw.to_i if (timeSlot > 0 and timeSlot < @numTimeSlots)
        end
      end

      return {
        numvlines: @numTimeSlots - 1,
        labels: bandwidthGraphTimeSlotLabels,
        keys: dests.keys,
        values: dests.values,
        title: "Bandwidth"
      }
    end # is this a JSON request for top N entries?


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
      if !params['resource'].present?
        paramHash = {}
        paramHash[:action] = "dash_bw"
        paramHash[:controller] = "reports"
        paramHash[:reportType] = params[:reportType]
        if params.has_key?(:reportTime) then
          paramHash[:reportTime] = params[:reportTime]
          if params[:reportTime] == "date_range" then
            paramHash[:fromDate] = params[:fromDate]
            paramHash[:toDate] = params[:toDate]
          end
        end
      end

      dbRecords.map do |rec|
        if !params['resource'].present?
           keyValue = link_to(rec.key, paramHash.merge({:resource=> rec.key}))
        else
          keyValue = h(rec.key)
        end
        {
          key: keyValue,
          sent: h(number_to_human_size rec.sent),
          recd: h(number_to_human_size rec.recd),
          total: h(number_to_human_size rec.total)
        }
      end
    when "src"
      devices = Deviceinfo.all
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

  def dbRecords
    case params['dataType']
    when "dst"
      @dbRecords ||= getDestinations
    when "src"
      @dbRecords ||= getSources
    end
  end

  def getDestinations
    return getDestinationsWithConditions(nil)
  end

  def getDestinationsWithConditions(initialQuery)
    if !params['resource'].present? then
      defaultQuery = @dbTable.select("#{@destIDColumn} as key").group("#{@destIDColumn}")
      defaultQuery = defaultQuery.where("#{@destIDColumn} ILIKE :search", search: "%#{params[:sSearch]}%") if (params[:sSearch].present? && !params[:sSearch].empty?)
    else
      #
      # If we are retrieving stat records for a particular IP, then get the port details for that server!
      #
      defaultQuery = @dbTable.select("destport as key").group("destport").where("#{@destIDColumn} = ?", params['resource'])
      defaultQuery = defaultQuery.where("destport ILIKE :search", search: "%#{params[:sSearch]}%") if (params[:sSearch].present? && !params[:sSearch].empty?)
    end

    records = initialQuery || defaultQuery
    records = records.where("deviceid = ?", params['device']) if params['device'].present?    
    records = records.select("sum(inbytes) as sent, sum(outbytes) as recd, sum(inbytes) + sum(outbytes) as total")
    records = setTimePeriod(records)
    records = records.order("#{sort_column} #{sort_direction}")
    records = records.page(page).per_page(per_page)
    records
  end

  def getSources
    return getSourcesWithConditions(nil)
  end

  def getSourcesWithConditions(initialQuery)
    defaultQuery = @dbTable.select("deviceid as key, sum(inbytes) as sent, sum(outbytes) as recd, sum(inbytes) + sum(outbytes) as total").
                            group("deviceid")
    defaultQuery = defaultQuery.where("#{@destIDColumn} = ?", params['resource']) if params['resource'].present?
    defaultQuery = defaultQuery.where("deviceid = ?", params['device']) if params['device'].present?
    records = initialQuery || defaultQuery
    records = records.where("deviceid = ?", params['device']) if params['device'].present?
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
    records = records.where("deviceid = ?", params['device']) if params['device'].present?    
    records = selectTimeIntervals(records)
    records = records.where(@destIDColumn.to_sym => destList) # Get the database records for only the top N dests
    records
  end

  def topDestPorts(n)
    return nil if !params['resource'].present?
    topDestPortsWithConditions(nil, n)
  end

  def topDestPortsWithConditions(initialQuery, n)
    if initialQuery.nil? then
      #
      # First get the top N ports consuming the bandwidth (IN + OUT bytes)
      #
      topPorts = @dbTable.select("destport as key, sum(inbytes) + sum(outbytes) as totalBW").where("#{@destIDColumn} = ?", params['resource']).
                          group("key").order("totalBW desc").limit(n)
      topPorts = setTimePeriod(topPorts)

      #
      # Once you have the top N destinations, then do a database query using this list. But now, get the bandwidth values
      # for each time period (hours/days/weeks) depending on the user selected time period
      #
      portList = Array.new(n)
      topPorts.each_with_index do |port, i|
        portList[i] = port.key
      end

      defaultQuery = @dbTable.select("destport as key").group("key").where("#{@destIDColumn} = ?", params['resource'])
      defaultQuery = defaultQuery.where(:destport => portList) # Get the database records for only the top N ports)
    end # initialQuery is nil?

    records = initialQuery || defaultQuery
    records = records.select("sum(inbytes) + sum(outbytes) as totalBW").order("totalBW desc")
    records = selectTimeIntervals(records)
    records
  end

  def columns
      %w[key sent recd total]
  end

  def sort_column
    columns[params[:iSortCol_0].to_i]
  end


end