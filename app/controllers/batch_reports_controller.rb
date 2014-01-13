require 'thinreports'
require 'gruff'

class BatchReportsController < ApplicationController

  include DviReportHelper
  
  @@reportGenerators = { 'dvi' => {generator: "dviReport", 
                                   title: "DVI Report"}
                       }

  def download_report

    @reportType = params['reportType']

    return if @reportType.nil? 

    begin
      report = create_report
      if !report.nil?
         send_data report.generate, filename: @reportFileName, 
                                    type: 'application/pdf', 
                                    disposition: 'attachment'
      else
         send_data File.read(@reportFileName), filename: @reportFileName,
                                               type: 'text/plain',
                                               disposition: 'attachment'
      end
    ensure
      FileUtils.remove_entry_secure @tmpDir
    end
  end

  def email_report
    
    @reportType = params['reportType']

    if !@reportType.nil? then
      begin
        report = create_report
        if !report.nil?
          mimeType = 'application/pdf'
          report.generate_file(@reportFileName) if !report.nil?
        else
          #
          # Maybe there was an error while generating the report. Just send the error.txt file.
          #
          mimeType = 'text/plain'
        end

        mailToAddress = params['mailto'] || ActionMailer::Base.smtp_settings[:to]
        PeregrineMailer.send_report(@@reportGenerators[@reportType][:title], @reportFileName, mimeType, mailToAddress).deliver
        noticeMsg = "#{@@reportGenerators[@reportType][:title]} has been mailed to: #{mailToAddress}."
      ensure
        FileUtils.remove_entry_secure @tmpDir
      end

    else
      noticeMsg = "Please select a report."
    end
    
    redirect_to '/dash_inventory', notice: noticeMsg

  end

  private

  def create_report
    @tmpDir = Dir.mktmpdir('pg_reports_', "#{Rails.root}/tmp")
    begin
      @reportFileName = "#{@tmpDir}/#{@reportType}_" + Time.now.strftime('%Y%m%d_%H%M%S') + ".pdf"
      generator = @@reportGenerators[@reportType][:generator]
      report = method(generator.to_sym).call @reportFileName
    rescue Exception => e  
      @reportFileName = "#{@tmpDir}/error_" + Time.now.strftime('%Y%m%d_%H%M%S') + ".txt"
      file = File.open(@reportFileName, 'w')
      file.puts("Unable to generate the report.")
      file.puts("Error: #{e.message}")
      file.puts(e.backtrace.inspect)
      file.close
      return nil
    rescue IOError => e
       #Ignore for now...
      return nil
    end #begin
  end

end
