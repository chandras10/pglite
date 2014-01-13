class PeregrineMailer < ActionMailer::Base
  default from: "peregrine7@i7nw.com"

  def send_alert(alert)
  	mail(:to => 'chandrashekar.m@gmail.com', :subject => 'I7 Alert')
  end

  def send_report(reportName, reportFile, mimeType, toAddress = nil)

  	attachments[reportName] = {
  		mime_type: mimeType,
  		content: File.read(reportFile) }

    toAddress = ActionMailer::Base.smtp_settings[:to] if toAddress.nil?
    mail(:to => toAddress, :subject => "Peregrine Report: #{reportName}")
    #mail(:to => 'sachin.s@i7nw.com', :subject => "Peregrine Report: #{reportName}")
  end

end
