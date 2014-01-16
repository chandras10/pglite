require 'rubygems'
require 'thinreports'
#require 'rmagick'
require 'gruff'

namespace :reports do

   desc 'Device Vulnerabilty Index (DVI) Report'

   task dvi_report: :environment do
    
    parmHash = Hash.new
    parmHash['reportTime'] = 'date_range'
    parmHash['fromDate'] = '2013-09-01'
    parmHash['toDate'] = '2014-01-01'
    mailToAddress = ActionMailer::Base.smtp_settings[:to]
    PeregrineMailer.delay.send_report(mailToAddress, 'dvi', parmHash)

   end # end of task
end #namespace