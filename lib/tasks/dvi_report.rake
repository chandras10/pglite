require 'rubygems'
require 'thinreports'
#require 'rmagick'
require 'gruff'

namespace :reports do

   desc 'Device Vulnerabilty Index (DVI) Report'

   task dvi_report: :environment do begin    

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


          # Get a list of operating system and distinct vulnerabilities discovered for each OS. The list of OSes is only for devices detected by us.
          #

          deviceVulns =  DviVuln.joins(:deviceinfo).joins(:vulnerability).
                         select("deviceinfo.macid as mac, deviceinfo.operatingsystem as os, deviceinfo.osversion as osver, vuln_id")

          # Aggregate the database records as follows:
          # for each OS = { osver = { CVE = { [array of devices] } } }
          # 

          osVulnMap = Hash.new
          deviceVulns.each do |dv|
             if osVulnMap[dv.os].nil? then osVulnMap[dv.os] = Hash.new end
             if osVulnMap[dv.os][dv.osver].nil? then 
                osVulnMap[dv.os][dv.osver] = Hash.new
             end
             if osVulnMap[dv.os][dv.osver][dv.vuln_id].nil? then 
                osVulnMap[dv.os][dv.osver][dv.vuln_id] = Array.new 
             end

             osVulnMap[dv.os][dv.osver][dv.vuln_id] << dv.mac
          end

          list = r.page.list(:os_vuln_list)
          
          g = Gruff::Pie.new
          g.hide_title
          g.theme_37signals

          osVulnMap.each do |os, osver_cve_device_map|

             # Plot the graph at OS level and ignore OS_Version. For each OS, 
             # we want the distinct/unique list of vulnerabilities
             #
             # We also want the list of devices running the given OS and OS_Version.
             #
             cveArray = Array.new
             deviceArray = Array.new
             osver_cve_device_map.each do |osver, cve_device_map|
                cveArray << cve_device_map.keys
             end

             g.data os, cveArray.uniq.length

             # Print per OS, per OS_version vulnerability counts
             osName = os
             osver_cve_device_map.keys.sort.each do |osver|
                osVersion = osver
                osVersion = "Unknown" if osVersion.strip.length == 0 # OS version is nil, empty or just whitespaces?

                list.add_row({:os_name => osName, 
                              :os_ver => osVersion, 
                              :device_count => osver_cve_device_map[osver].values.flatten.compact.uniq.length,
                              :vuln_count => osver_cve_device_map[osver].keys.count})
                osName = " " #print OS name only once and not for every version row

             end
          end

          g.write graphNames[1]
          r.page.item(:graph2).src(graphNames[1]) if File.exists? graphNames[1]


          #
          # List out all the devices, their DVI and other attributes 
          #
          lineCounter = 1
          r.start_new_page :layout => :dvi_table
          snortAlerts_srcmac = Hash.new
          snortAlerts_dstmac = Hash.new

          deviceList.each do |d|

            vulns = DviVuln.joins(:vulnerability).
                         select("count(*) as cnt").
                         where("mac = ?", d.macid)
            
            #snortAlerts = Alertdb.select("count(*) as cnt").
            #                  where("srcmac = ? OR dstmac = ?", d.macid, d.macid)
            snortAlerts_srcmac[d.macid] = Alertdb.find_by_sql("select srcmac as macid, sigid, priority, message, count(*) as cnt from alertdb 
                                               where (srcmac = '#{d.macid}') 
                                               group by srcmac, sigid, priority, message
                                               order by srcmac, priority, sigid")
            snortAlerts_dstmac[d.macid] = Alertdb.find_by_sql("select dstmac as macid, sigid, priority, message, count(*) as cnt from alertdb 
                                                where (dstmac = '#{d.macid}') 
                                                group by dstmac, sigid, priority, message
                                                order by dstmac, priority, sigid")

            record = { :line_no => "#{lineCounter}.",
                       :macid => d.macid.upcase, 
                       :username => d.username,
                       :devicename => d.devicename,
                       :os => "#{d.operatingsystem} #{d.osversion}",
                       :compromised => ((d.weight & 0x00FF0000) > 0) ? "Yes" : "No", 
                       :ids_count => snortAlerts_srcmac[d.macid].count + snortAlerts_dstmac[d.macid].count,
                       :vuln_count => vulns.first.cnt,
                       :dvi => "#{d.dvi.round(2)}   (#{dvi_severityHash[d.macid]})"
                    }
            r.page.list.add_row(record)

            # TODO: Color rows different if there is a jailbroken device - d.weight & 0x00FF0000 > 0

            lineCounter += 1
          end

          #for each device, print out the list of CVE notices
          deviceList.each do |d|

            vulns = DviVuln.joins(:vulnerability).
                         select("vuln_id, vulnerability.summary as desc, vulnerability.cvss_score as score").
                         where("mac = ?", d.macid)
            
            next if vulns.count == 0

            r.start_new_page :layout => :device_cve_notices
            r.page.list(:cve_list).header({:mac => d.macid.upcase,
                                           :devicename => d.devicename,
                                           :username => d.username,
                                           :os_name => d.operatingsystem,
                                           :os_version => d.osversion})

            lineCounter = 1
            vulns.each do |v|

               record = {:vuln_no => "#{lineCounter}.",
                         :cve_id => v.vuln_id,
                         :cve_summary => v.desc,
                         :cve_score => v.score
                        }

               r.page.list(:cve_list).add_row(record)
               lineCounter += 1
            end
          end #for each device

          
          deviceList.each do |d|
            next if (snortAlerts_srcmac[d.macid].count == 0) && (snortAlerts_dstmac[d.macid].count == 0)

            r.start_new_page :layout => :device_intrusion_notices
            r.page.list(:ids_list).header({:mac => d.macid.upcase,
                                           :devicename => d.devicename,
                                           :username => d.username,
                                           :os_name => d.operatingsystem,
                                           :os_version => d.osversion})


            lineCounter = 1
            snortAlerts_srcmac[d.macid].each do |rec|
               case rec.priority
               when 1 
                  priority = "High"
               when 2 
                  priority = "Medium"
               when 3 
                  priority = "Low"
               when 4 
                  priority = "Very Low"
               else   
                  priority = "Unknown"
               end

               record = {:ids_no => "#{lineCounter}.",
                         :ids_sig_id => rec.sigid,
                         :ids_priority => priority,
                         :ids_message => rec.message,
                         :ids_sigid_occurences => rec.cnt
                        }

               r.page.list(:ids_list).add_row(record)
               lineCounter += 1
            end
            snortAlerts_dstmac[d.macid].each do |rec|
               case rec.priority
               when 1 
                  priority = "High"
               when 2 
                  priority = "Medium"
               when 3 
                  priority = "Low"
               when 4 
                  priority = "Very Low"
               else   
                  priority = "Unknown"
               end

               record = {:ids_no => "#{lineCounter}.",
                         :ids_sig_id => rec.sigid,
                         :ids_priority => priority,
                         :ids_message => rec.message,
                         :ids_sigid_occurences => rec.cnt
                        }

               r.page.list(:ids_list).add_row(record)
               lineCounter += 1
            end

          end
       end

       report.generate_file(reportFileName + ".pdf")

       File.delete graphNames[0] if File.exists? graphNames[0]
       File.delete graphNames[1] if File.exists? graphNames[1]

   rescue Exception => e
      file = File.open(reportFileName + ".txt", 'w')
      file.write("Unable to generate the report.\n")
      file.write("Error: #{e.message}\n\n")
      file.write(e.backtrace.inspect)
   rescue IOError => e
      #Ignore for now...
   end #begin (for exception handling)       
   end

end #namespace
