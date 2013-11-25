class PeregrineMailer < ActionMailer::Base
  default from: "peregrine7@i7nw.com"

  def send_alert(alert)
  	mail(:to => 'chandrashekar.m@gmail.com', :subject => 'I7 Alert')
  end
end
