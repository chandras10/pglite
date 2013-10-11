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
           Rails.logger.debug "numTimeSlots = #{@numTimeSlots}"
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
  $BW_MEASURE = 2 ** 10

  def bandwidth_label
      label = "(bytes)"
      if ($BW_MEASURE > 1000000) then
         label = "(Mbytes)"
      elsif ($BW_MEASURE > 1000) then
         label = "(Kbytes)"
      end
  end

end
