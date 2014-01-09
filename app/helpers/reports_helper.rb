module ReportsHelper
  def weekLabels(date)
       currentDate = date.end_of_week
       labelArray = Array.new
       (@numTimeSlots-1).downto(0) do |i|
           labelArray << (currentDate - i.week).to_date.to_s #strftime('%d-%b')
       end
       return labelArray
  end

  def bandwidthGraphTimeSlotLabels
    case params['reportTime']
    when "past_hour"
       labelArray = Array.new(@numTimeSlots, "")
       interval = 60/(@numTimeSlots-1)
       pastHour = (Time.now - 1.hour)    
       @numTimeSlots.times do |i|
           t = pastHour + (i * interval).minutes
           labelArray[i] = ("%02d" % t.hour) + ":" + ("%02d" % t.min)
       end
    when "past_week"
       labelArray = Date::ABBR_DAYNAMES.dup
       currentDayOfWeek = Date.today.wday
       labelArray.rotate!(currentDayOfWeek+1)
       return labelArray
    when "past_month"
       labelArray = weekLabels(Date.today)
    when "date_range"
       labelArray = Array.new(@numTimeSlots, "")

         begin
            fromDate = Date.parse(params['fromDate'], 'YYYY-MM-DD').to_time
         rescue
            fromDate = Date.today #if the incoming parameter is an invalid date format, then pick TODAY as the date!
            params['fromDate'] = fromDate.to_s
         end
         begin
            toDate = Date.parse(params['toDate'], 'YYYY-MM-DD').to_time
         rescue
            # in case of parsing error, take FROMDATE + 1 as the end date...
            params['toDate'] = (Date.parse(params['fromDate'], 'YYYY-MM-DD') + 1.day).to_s
            toDate = (Date.parse(params['fromDate'], 'YYYY-MM-DD') + 1.day).to_time
         end

       case @timeSlot
       when "month"
            monthNames = Date::ABBR_MONTHNAMES
            startMonth = ActiveRecord::Base.connection.select_value(ActiveRecord::Base.send(:sanitize_sql_array, 
                         ["select date_part('month', date '#{fromDate}')"])).to_i
            @numTimeSlots.times do |i|
                ii = ((startMonth + i) % 12) == 0 ? 12 : ((startMonth + i) % 12)
                labelArray[i] = monthNames[ii] 
            end
       when "week"
           labelArray = weekLabels(toDate)
       when "day"
           skipLabel = (@numTimeSlots/10.0).round
           skipLabel = 1 if (skipLabel == 0) #if the timeslots are less than 10, then print every label...
           @numTimeSlots.times do |i|
               labelArray[i] = (fromDate + i.day).to_date.to_s if (i % skipLabel == 0)
           end
           labelArray[@numTimeSlots-1] = toDate.to_date.to_s
           return labelArray
       end
    else #default is TODAY
       labelArray = Array.new(@numTimeSlots, "")
       @numTimeSlots.times do |i|
           next if (i%2 != 0)
           if (i < 12) then
               labelArray[i] = "%02d:00 AM" % i
           elsif (i == 12) then
               labelArray[i] = "12:00 PM"
           else
               labelArray[i] = "%02d:00 PM" % (i - 12)
           end
       end

       if params['reportTime'] == "past_day" then
          currentHour = Time.now.strftime("%H.%M").to_f.ceil
          labelArray.rotate!(currentHour+1)
       end
    end
    return labelArray
  end  

  #
  # Bandwidth data will be shown in M/K/bytes depending on the variable value below.
  #  2 ** 0 = one byte; 1K = 2 ** 10;  1M = 2 ** 20
  #
  $BW_MEASURE = 2 ** 0

  def bandwidth_label
      label = "(bytes)"
      if ($BW_MEASURE > 1000000) then
         label = "(Mbytes)"
      elsif ($BW_MEASURE > 1000) then
         label = "(Kbytes)"
      end
  end

  #
  # Set from and to limits to the incoming query based on relative parameters like past_day/week/month etc.
  #
  # ASSUMPTION: Incoming query references a table(s) which has column named 'timestamp'
  #
  def setTimePeriod(dbQuery)

    if (dbQuery.nil? || dbQuery.empty?)
      return dbQuery
    end

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

  #
  # Set from and to limits to the incoming query based on relative parameters like past_day/week/month etc.
  # Once you filter the database records within the date range, sub divide the aggregation on hourly/weekly/daily basis.
  # For eg: IF "past_day" is needed, then select records timestamped <= CURRENT - 24 hours. And then sum/count the values
  # for each of the 24 hours and return a 24 hour array for each 'group'.
  #
  # ASSUMPTION: Incoming query references a table(s) which has column named 'timestamp'
  #
  def selectTimeIntervals(dbQuery)

    if dbQuery.nil? || dbQuery.empty?
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
