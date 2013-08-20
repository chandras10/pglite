require 'thinreports'
require 'gruff'

class BatchReportsController < ApplicationController
  
  include DviReportHelper

  TRUNCATE_MESG_LENGTH = 400
   
  def dvi_report
    begin
       @tmpDir = Dir.mktmpdir(nil, "/var/tmp")

       report = dviReport

       if !report.nil?
          send_data report.generate, filename: "DVI_report.pdf", 
                                     type: 'application/pdf', 
                                     disposition: 'attachment'
       end
    rescue Exception => e
       file = File.open("error.txt", 'w')
       file.write("Unable to generate the report.\n")
       file.write("Error: #{e.message}\n\n")
       file.write(e.backtrace.inspect)
    rescue IOError => e
       #Ignore for now...
    ensure
       FileUtils.remove_entry_secure @tmpDir   
    end #begin (for exception handling)      

  end # end of dvi_report
end
