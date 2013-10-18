class I7alertsController < ApplicationController
  before_filter :signed_in_user, only: [:index]

  def index
    set_constants

    dbQuery = I7alert
    dbQuery = addTimeLinesToDatabaseQuery(dbQuery)
    timeQueryString = dbQuery.to_sql.scan(/SELECT (.*) FROM .* WHERE\s+\((.*)\).*/i)


    @alerts = I7alert.select('timestamp, i7alertdef.id as id, i7alertdef.priority as priority, 
                              i7alertdef.description as description, i7alertclassdef.description as classtype, 
                              proto, srcmac, srcip, srcport, dstmac, dstip, dstport, pcap, message').
                      joins('LEFT OUTER JOIN i7alertdef ON i7alertdef.id = i7alert.id 
                             LEFT OUTER JOIN i7alertclassdef ON i7alertclassdef.id = i7alertdef.classid').
                      where("i7alertdef.classid NOT in (#{Rails.configuration.i7alerts_ignore_classes.join('')})").
                      where("#{timeQueryString[0][1]}")
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: I7alertsDatatable.new(view_context, timeQueryString)}
    end
  end

  private

  def set_constants
     @availableTimeLines = {
                            "today"       => "Today",
                            "past_hour"   => "Past Hour",
                            "past_day"    => "Past 24 Hours",
                            "past_week"   => "Past Week",
                            "past_month"  => "Past Month",
                            "date_range"  => "Choose Dates"
                           }
  end  

  def addTimeLinesToDatabaseQuery(dbQuery)

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
         dbQuery = dbQuery.select("MOD(cast(date_part('minute', timestamp) as INT), #{@numTimeSlots}) as time").
                           where("timestamp > (CURRENT_TIMESTAMP - '1 hour'::interval)")         
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
         dbQuery = dbQuery.select("EXTRACT(day from timestamp - (current_timestamp - '7 day'::interval)) as time").
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
            dbQuery = dbQuery.select("EXTRACT(day from timestamp - date '#{fromDate}') as time")
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

    return dbQuery

  end

end
