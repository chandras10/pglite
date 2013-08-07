require 'rubygems'
require 'thinreports'
#require 'rmagick'
require 'gruff'

namespace :reports do

   desc 'Device Vulnerabilty Index (DVI) Report'

   task dvi_report: :environment do begin    
       reportGenTimeStamp = Time.now.strftime('%Y%m%d_%H%M%S')
       reportFileName = "dvi_report_" + reportGenTimeStamp

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

          r.events.on :page_create do |e|
            e.page.item(:page_number).value(e.page.no)
            e.page.item(:report_create_date).value(Time.now)
          end

          # First page - Summary

          # Set up the headers and labels
          r.start_new_page :layout => :summary    
          r.page.values(:company_name  => page1_header[:company_name],
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
          devices = Deviceinfo.
                               select("macid, username, devicename, to_char(updated_at, 'YYYY-MM-DD HH') as updated_at, dvi, weight").
                               where("ipaddr <> '' ").
                               order("dvi DESC")
          
          dvi_counter = Array.new(3, 0)
          dvi_severityHash = Hash.new
          # Array Index 0: High, 1: Med, 2: Low
          devices.each do |d|
             if !d.dvi.nil?
                case d.dvi
                when d.dvi >= 0.7 && d.dvi <= 1.0
                   dvi_counter[0] += 1
                   dvi_severityHash[d.macid] = "High"
                when d.dvi > 0.4 && d.dvi < 0.7
                   dvi_counter[1] += 1
                   dvi_severityHash[d.macid] = "Medium"
                else
                   dvi_counter[2] += 1
                   dvi_severityHash[d.macid] = "Low"
                end
             end
          end

          #g = Gruff::Pie.new
          #g.title = " "
          #g.data 'High', dvi_counter[0]
          #g.data 'Medium', dvi_counter[1]
          #g.data 'Low', dvi_counter[2]
   
          #g.write "#{Rails.root}/tmp/graph1.png"

          g = Gruff::SideBar.new('600x600')
          g.hide_title
          g.x_axis_label = "Number of devices"
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

          g.write "#{Rails.root}/tmp/graph1_#{reportGenTimeStamp}.png"


          r.page.item(:graph1).src("#{Rails.root}/tmp/graph1_#{reportGenTimeStamp}.png") if File.exists? "#{Rails.root}/tmp/graph1_#{reportGenTimeStamp}.png"

          # select prod.os_name, count(*) from dvi_vuln d, vulnerability v, product prod, vuln_product vp  
          # where d.vuln_id = v.id and vp.vuln_id = v.id and vp.product_id = prod.id 
          # group by prod.os_name;

          slice_vuln_by_os = DviVuln.joins(:vulnerability).
                             joins("INNER JOIN vuln_product ON vuln_product.vuln_id = vulnerability.id").
                             joins("INNER JOIN product ON vuln_product.product_id = product.id").
                             select("product.os_name, count(*) as cnt").
                             group("product.os_name").order("cnt DESC")

          list = r.page.list(:os_vuln_list)
          
          g = Gruff::Pie.new
          g.hide_title
          g.theme_37signals
          slice_vuln_by_os.each do |os_rec|
             g.data os_rec.os_name, os_rec.cnt.to_i
             list.add_row({:os_name => os_rec.os_name, :count => os_rec.cnt})
          end

          g.write "#{Rails.root}/tmp/graph2_#{reportGenTimeStamp}.png"
          r.page.item(:graph2).src("#{Rails.root}/tmp/graph2_#{reportGenTimeStamp}.png") if File.exists? "#{Rails.root}/tmp/graph2_#{reportGenTimeStamp}.png"          

          lineCounter = 1
          r.start_new_page :layout => :dvi_table
          devices.each do |d|

            vulns = DviVuln.joins(:vulnerability).
                         select("count(*) as cnt").
                         where("mac = ?", d.macid)

            snortAlerts = Alertdb.select("count(*) as cnt").
                              where("srcmac = ? OR dstmac = ?", d.macid, d.macid)

            record = { :line_no => "#{lineCounter}.",
                       :macid => d.macid.upcase, 
                       :username => d.username,
                       :devicename => d.devicename,
                       :updated_at => d.updated_at,
                       :ids_count => snortAlerts.first.cnt,
                       :vuln_count => vulns.first.cnt,
                       :dvi => "#{d.dvi.round(2)}   (#{dvi_severityHash[d.macid]})"
                    }
            r.page.list.add_row(record)

            # TODO: Color rows different if there is a jailbroken device - d.weight & 0x00FF0000 > 0

            lineCounter += 1
          end
       end

       report.generate_file(reportFileName + ".pdf")

       File.delete "#{Rails.root}/tmp/graph1_#{reportGenTimeStamp}.png" if File.exists? "#{Rails.root}/tmp/graph1_#{reportGenTimeStamp}.png"
       File.delete "#{Rails.root}/tmp/graph2_#{reportGenTimeStamp}.png" if File.exists? "#{Rails.root}/tmp/graph2_#{reportGenTimeStamp}.png"

   rescue Exception => e
      file = File.open(reportFileName + ".txt", 'w')
      file.write("Unable to generate the report.")
      file.write("Error: #{e.message}")
      file.write(e.backtrace.inspect)
   rescue IOError => e
      #Ignore for now...
   end       
   end

end #namespace
