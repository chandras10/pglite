require 'thinreports'
require 'gruff'

class BatchReportsController < ApplicationController

  TRUNCATE_MESG_LENGTH = 400

  def dvi_report
   begin    

       reportGenTimeStamp = Time.now.strftime('%Y%m%d_%H%M%S')
       reportFileName = "dvi_report_" + reportGenTimeStamp

       graphNames = [ "#{Rails.root}/tmp/graph1_#{reportGenTimeStamp}.png", 
                      "#{Rails.root}/tmp/graph2_#{reportGenTimeStamp}.png" ]


       page1_header = {
                   :company_name => "i7 Networks Pvt Ltd.",
                   :company_addr_line1 => "Koramangala",
                   :company_addr_line2 => "Bangalore",
                   :company_addr_line3 => "",
                   :graphTitle => {
                            :title1 => "Device Vulnerability Index (DVI)",
                            :title2 => "Vulnerabilities By Operating System"
                   }
       }


       report = ThinReports::Report.create do |r|
          
          r.use_layout "#{Rails.root}/app/reports/dvi_report_header.tlf", :id => :summary
          r.use_layout "#{Rails.root}/app/reports/dvi_vuln_summary_table.tlf", :id => :vuln_summary          
          r.use_layout "#{Rails.root}/app/reports/dvi_table.tlf", :id => :dvi_table
          r.use_layout "#{Rails.root}/app/reports/dvi_report_device_cve_notices.tlf", :id => :device_cve_notices
          r.use_layout "#{Rails.root}/app/reports/dv_report_device_intrusion_notices.tlf", :id => :device_intrusion_notices

          r.events.on :page_create do |e|
            e.page.item(:page_number).value(e.page.no)
            e.page.item(:report_create_date).value(Time.now)
          end

          # First page - Summary

          # Set up the headers and labels
          r.start_new_page :layout => :summary    
          r.page.values(:company_name       => page1_header[:company_name],
                        :company_addr_line1 => page1_header[:company_addr_line1],
                        :company_addr_line2 => page1_header[:company_addr_line2],
                        :company_addr_line3 => page1_header[:company_addr_line3],
                        :graph1_title       => page1_header[:graphTitle][:title1],
                        :graph2_title       => page1_header[:graphTitle][:title2])

          list = r.page.list(:dvi_score_legend)
          list.add_row({:dvi_range => "0.70  -   1.0",   :severity_label => "High"})
          list.add_row({:dvi_range => "0.40  -   0.69", :severity_label => "Medium"})
          list.add_row({:dvi_range => "< 0.40",     :severity_label => "Low"})
  
          # Draw the first graph
          deviceList = Deviceinfo.
                               select("macid, username, devicename, operatingsystem, osversion, weight, to_char(updated_at, 'YYYY-MM-DD HH') as updated_at, dvi, weight").
                               where("ipaddr <> '' ").
                               order("dvi DESC")
          deviceVulns =  DviVuln.joins(:deviceinfo).joins(:vulnerability).
                                 select("deviceinfo.macid as mac, deviceinfo.operatingsystem as os, deviceinfo.osversion as osver, vuln_id, 
                                         vulnerability.summary as desc, vulnerability.cvss_score as score, vulnerability.cvss_access_complexity as vuln_severity")

          snortAlerts = Alertdb.select("srcmac, dstmac, sigid, priority, message, count(*) as cnt").group("srcmac, dstmac, sigid, priority, message")

          
          dvi_counter = Array.new(3, 0)
          dvi_severityHash = Hash.new
          deviceList.each do |d|
             next if d.dvi.nil?
             
             if (d.dvi >= 0.7 && d.dvi <= 1.0)
                dvi_counter[0] += 1
                dvi_severityHash[d.macid] = "High"
             elsif (d.dvi >= 0.4 && d.dvi < 0.7)
                dvi_counter[1] += 1
                dvi_severityHash[d.macid] = "Med"
             else
                dvi_counter[2] += 1
                dvi_severityHash[d.macid] = "Low"
             end

          end # foreach device

          #
          # DVI graph showing device list sliced by DVI severity (HIGH/MED/LOW)
          #
          g = Gruff::SideBar.new
          g.hide_title
          g.x_axis_label = "Number of deviceList"
          g.y_axis_label = "DVI Severity"
          g.top_margin = 0
          g.bottom_margin = 0

          g.center_labels_over_point = true

          g.sort = false
          #g.hide_legend = true

          #g.theme_37signals
          #g.theme_keynote
          g.theme_pastel

          g.data(:High,   [dvi_counter[0], 0, 0])
          g.data(:Medium, [0, dvi_counter[1], 0])
          g.data(:Low,    [0, 0, dvi_counter[2]])

          g.minimum_value = 0
          g.marker_count = 3

          g.labels = { 0 => 'High', 1 => 'Medium', 2 => 'Low' }

          g.write graphNames[0]

          r.page.item(:graph1).src(graphNames[0]) if File.exists? graphNames[0]

          # Graph 2: Get a list of operating system and distinct vulnerabilities discovered for each OS. The list of OSes is only for devices detected by us.
          #

          list = r.page.list(:os_vuln_list)
          
          g = Gruff::Pie.new
          g.hide_title
          g.theme_37signals

          osList = deviceVulns.map {|dv| dv.os}.uniq.sort
          osList.each do |os|

             # Breakup the vulnerability count and device count per OS and its version
             osName = os
             osRecs = deviceVulns.select {|dv| dv.os == os}
             osVersionList = osRecs.map {|dv| dv.osver}.uniq.sort
             osVulnCount = 0
             osVersionList.each do |osver|
             	deviceCount = osRecs.select{|dv| dv.osver == osver}.map{|dv| dv.mac}.uniq.count
             	vulnCount   = osRecs.select{|dv| dv.osver == osver}.map{|dv| dv.vuln_id}.uniq.count
                osVulnCount += vulnCount

                list.add_row({:os_name => osName, 
                              :os_ver => (osver != "" ? osver : "Unknown"), 
                              :device_count => deviceCount,
                              :vuln_count => vulnCount})
                osName = " " #print OS name only once and not for every version row
             end

             g.data os, osVulnCount

          end

          g.write graphNames[1]
          r.page.item(:graph2).src(graphNames[1]) if File.exists? graphNames[1]

          r.start_new_page :layout => :vuln_summary
          r.page.values( :page_title => "Vulnerability Events",
          	             :event_type => "vulnerabilities: ")

          vulnSeverityValues = ["CRITICAL", "HIGH", "MEDIUM", "LOW", ""] # copied these from vulnerability table in the database
          vulnSeverityValues.each do |severity|
          	 if severity.empty?
          	    vulns = deviceVulns.inject(Hash.new(0)) {|hash, dv| hash[dv.vuln_id] += 1 if dv.vuln_severity.nil?; hash}
          	    severity = "Unknown"
          	 else
          	    vulns = deviceVulns.inject(Hash.new(0)) {|hash, dv| hash[dv.vuln_id] += 1 if dv.vuln_severity == severity ; hash}
          	 end
             vulns.keys.sort.each do |cve|
             	rec = deviceVulns.detect { |dv| dv.vuln_id == cve } 
                r.page.list.add_row ( {
                                       :severity => severity,
                                       :description => rec.desc.truncate(TRUNCATE_MESG_LENGTH, :separator => ' '),
                                       :id => rec.vuln_id,
                                       :count => vulns[cve]
          	 	                    })
                severity = " "
             end
          end

          r.start_new_page :layout => :vuln_summary
          r.page.values( :page_title => "Intrusion Events",
          	             :event_type => "possible intrusions: ")

          snortPriority = ["High", "Medium", "Low", "Very Low"]
          for priorityIndex in 0..4
          	 if priorityIndex == 0
          	    snorts = snortAlerts.inject(Hash.new(0)) {|hash, sa| hash[sa.sigid] += sa.cnt.to_i if sa.priority.nil?; hash}
          	    priorityLabel = "Unknown"
          	 else
          	    snorts = snortAlerts.inject(Hash.new(0)) {|hash, sa| hash[sa.sigid] += sa.cnt.to_i if sa.priority == priorityIndex ; hash}
          	    priorityLabel = snortPriority[priorityIndex]
          	 end
             snorts.keys.sort.each do |snortID|
             	rec = snortAlerts.detect { |sa| sa.sigid == snortID } 
                r.page.list.add_row ( {
                                       :severity => priorityLabel,
                                       :description => rec.message.truncate(TRUNCATE_MESG_LENGTH, :separator => ' '),
                                       :id => snortID,
                                       :count => snorts[snortID]
          	 	                    })
                priorityLabel = " "
             end
          end
          # Page 3:
          # List out all the devices, their DVI, Snort alert counts and other attributes 
          #
          lineCounter = 1
          r.start_new_page :layout => :dvi_table

          deviceList.each do |d|

            vulns = deviceVulns.select {|dv| dv.mac == d.macid }
            snorts = snortAlerts.select {|sa| (sa.srcmac == d.macid || sa.dstmac == d.macid) }
            
            r.page.list.add_row( { :line_no => "#{lineCounter}.",
                                   :macid => d.macid.upcase, 
                                   :username => d.username,
                                   :devicename => d.devicename,
                                   :os => "#{d.operatingsystem} #{d.osversion}",
                                   :compromised => ((d.weight & 0x00FF0000) > 0) ? "Yes" : "No", 
                                   :ids_count => snorts.uniq {|sa| sa.sigid}.count, 
                                   :vuln_count => vulns.uniq {|v| v.vuln_id}.count,
                                   :dvi => "#{d.dvi.round(2)}   (#{dvi_severityHash[d.macid]})"
                                 })

            # TODO: Color rows different if there is a jailbroken device - d.weight & 0x00FF0000 > 0
            lineCounter += 1
          end

          #for each device, print out the list of CVE notices and its Snort Alerts
          deviceList.each do |d|

            vulns = deviceVulns.select {|dv| dv.mac == d.macid }

            next if vulns.count == 0

            r.start_new_page :layout => :device_cve_notices

            r.page.list(:cve_list).header({:mac => d.macid.upcase,
                                           :devicename => d.devicename,
                                           :username => d.username,
                                           :os_name => d.operatingsystem,
                                           :os_version => d.osversion})

            lineCounter = 1
            vulns.each do |v|

               r.page.list(:cve_list).add_row( {:vuln_no => "#{lineCounter}.",
                                                :cve_id => v.vuln_id,
                                                :cve_summary => v.desc.truncate(TRUNCATE_MESG_LENGTH, :separator => ' '),
                                                :cve_score => v.score
                                               })
               lineCounter += 1
            end

            snortPriority = ["Unknown", "High", "Medium", "Low", "Very Low"]
            snorts = snortAlerts.select {|sa| (sa.srcmac == d.macid || sa.dstmac == d.macid) }
            next if snorts.count == 0
            snortCountHash = snorts.inject(Hash.new(0)) {|h, s| h[s.sigid] += 1; h }

            r.start_new_page :layout => :device_intrusion_notices
            r.page.list(:ids_list).header({:mac => d.macid.upcase,
                                           :devicename => d.devicename,
                                           :username => d.username,
                                           :os_name => d.operatingsystem,
                                           :os_version => d.osversion})


            lineCounter = 1            
            snortCountHash.keys.sort.each do |id|

               # Get the first Snort Alert that matches the given Snort ID. We need it to grab the priority and message for that ID.
               rec = snorts.detect { |s| s.sigid == id } 
               r.page.list(:ids_list).add_row( {:ids_no => "#{lineCounter}.",
                                                :ids_sig_id => rec.sigid,
                                                :ids_priority => snortPriority[rec.priority],
                                                :ids_message => rec.message.truncate(TRUNCATE_MESG_LENGTH, :separator => ' '),
                                                :ids_sigid_occurences => snortCountHash[id]
                                               } )
               lineCounter += 1
            end #for each snort alert

          end # each Device
       end # Report

       send_data report.generate, filename: "#{reportFileName}.pdf", 
                               type: 'application/pdf', 
                               disposition: 'attachment'

       #report.generate_file(reportFileName + ".pdf")
   rescue Exception => e
      file = File.open(reportFileName + ".txt", 'w')
      file.write("Unable to generate the report.\n")
      file.write("Error: #{e.message}\n\n")
      file.write(e.backtrace.inspect)
   rescue IOError => e
      #Ignore for now...
   ensure
       File.delete graphNames[0] if File.exists? graphNames[0]
       File.delete graphNames[1] if File.exists? graphNames[1]   	
   end #begin (for exception handling)       

  end
end
