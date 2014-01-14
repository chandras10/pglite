module ConstantsHelper
  def set_IPstatTypes_constants
       @availableBandwidthReportTypes = { 
                                          "internalIP"  => "Internal Servers",
                                          "internalAPP" => "Internal Applications",
                                          "externalIP"  => "External Servers",
                                          "externalAPP" => "External Applications",
                                          "byodIP"      => "BYODs",
                                          "external_urlcat"      => "Website Categories",
                                          "external_hlurlcat"    => "Website Category Groups"
                                        }
  end

  def set_timeLine_constants
       @availableTimeLines = {
                              "today"       => "Today",
                              "past_hour"   => "Past Hour",
                              "past_day"    => "Past 24 Hours",
                              "past_week"   => "Past Week",
                              "past_month"  => "Past Month",
                              "date_range"  => "Choose Dates"
                             }

       @priorityLabels = Array["High", "Medium", "Low", "Very Low"]
  end

  def reports_tmpdir
    Dir.mktmpdir('pg_reports_', "#{Rails.root}/tmp")
  end
end