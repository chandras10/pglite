class PeregrineMailer < ActionMailer::Base
  default from: "peregrine7@i7nw.com"

  def send_alert(alert)
  	mail(:to => 'i7mail@i7nw.com', :subject => 'I7 Alert')
  end

  def send_report(toAddress, reportType, parmHash)

    reportObject = BatchReports.Report(reportType)
    return if reportObject.nil?

    reportFile = reportObject.create(parmHash)
  	attachments[reportObject.title] = {
  		mime_type: 'application/pdf',
  		content: File.read(reportFile) }

    mail(:to => toAddress, :subject => "Peregrine Report: #{reportObject.title}").deliver
   
    FileUtils.remove_entry_secure File.dirname(reportFile)

  end

end
