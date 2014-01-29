require 'thinreports'
require 'gruff'

class BatchReportsController < ApplicationController

  def select_report
    set_timeLine_constants
    set_report_filters
  end
  
  def download_report

    reportType = params['reportType']
    reportObject = BatchReports.Report(reportType)

    if !reportObject.nil? then
      begin
        report = reportObject.create(params)
        data = File.read(report) 
        send_data data, filename: File.basename(report), 
                        type: 'application/pdf', 
                        disposition: 'attachment'
      ensure
        FileUtils.remove_entry_secure File.dirname(report)
      end

    else
      noticeMsg = ("Invalid Report: #{reportType}. " if !reportType.nil?) || ""
      noticeMsg += "Please select a report."

      redirect_to '/dash_inventory', notice: noticeMsg
    end

  end


  def email_report
    
    reportType = params['reportType']
    reportObject = BatchReports.Report(reportType)

    if !reportObject.nil? then

      mailToAddress = params['mailto'] || ActionMailer::Base.smtp_settings[:to]
      PeregrineMailer.delay.send_report(mailToAddress, reportType, params)
      
      noticeMsg = "#{reportObject.title} will be mailed to: #{mailToAddress}."
    else
      noticeMsg = ("Invalid Report: #{reportType}. " if !reportType.nil?) || ""
      noticeMsg += "Please select a report."
    end
    
    redirect_to '/dash_inventory', notice: noticeMsg

  end

end
