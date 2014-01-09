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


end