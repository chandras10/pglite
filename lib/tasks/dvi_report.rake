require 'rubygems'
require 'thinreports'
#require 'rmagick'
require 'gruff'

namespace :reports do

   desc 'Vulnerabilty Report'

   task vulnerability_report: :environment do

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
          
          r.use_layout "#{Rails.root}/app/reports/device_vulnerability_report.tlf", :id => :summary
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
                               select("macid, username, devicename, to_char(updated_at, 'YYYY-MM-DD HH') as updated_at, dvi").
                               where("ipaddr <> '' ").
                               order("dvi DESC")
          
          Rails.logger.debug "Device count = #{devices.count}"

          dvi_counter = Array.new(3, 0)
          # Array Index 0: High, 1: Med, 2: Low
          devices.each do |d|
             if !d.dvi.nil?
                case d.dvi
                when d.dvi >= 0.7 && d.dvi <= 1.0
                   dvi_counter[0] += 1
                when d.dvi > 0.4 && d.dvi < 0.7
                   dvi_counter[1] += 1
                else
                   dvi_counter[2] += 1
                end
             end
          end

          #g = Gruff::Pie.new
          #g.title = " "
          #g.data 'High', dvi_counter[0]
          #g.data 'Medium', dvi_counter[1]
          #g.data 'Low', dvi_counter[2]
   
          #g.write "#{Rails.root}/tmp/graph1.png"

          g = Gruff::Bar.new('600x600')
          g.title = " "
          g.sort = false
          #g.hide_legend = true

          g.theme_37signals

          g.data(:High, dvi_counter[0])
          g.data(:Medium, dvi_counter[1])
          g.data(:Low, dvi_counter[2])

          #g.labels = { 0 => 'High', 1 => 'Medium', 2 => 'Low' }

          g.minimum_value = 0

          g.write "#{Rails.root}/tmp/graph1.png"


          r.page.item(:graph1).src("#{Rails.root}/tmp/graph1.png") if File.exists? "#{Rails.root}/tmp/graph1.png"

          # select prod.os_name, count(*) from dvi_vuln d, vulnerability v, product prod, vuln_product vp  
          # where d.vuln_id = v.id and vp.vuln_id = v.id and vp.product_id = prod.id 
          # group by prod.os_name;

          slice_vuln_by_os = DviVuln.joins(:vulnerability).
                             joins("INNER JOIN vuln_product ON vuln_product.vuln_id = vulnerability.id").
                             joins("INNER JOIN product ON vuln_product.product_id = product.id").
                             select("product.os_name, count(*) as cnt").
                             group("product.os_name")

          g = Gruff::Pie.new
          g.title = " "
          g.theme_37signals
          slice_vuln_by_os.each do |os_rec|
             g.data os_rec.os_name, os_rec.cnt.to_i
          end

          g.write "#{Rails.root}/tmp/graph2.png"
          r.page.item(:graph2).src("#{Rails.root}/tmp/graph2.png") if File.exists? "#{Rails.root}/tmp/graph2.png"          

          r.start_new_page :layout => :dvi_table
          devices.each do |d|
            record = { :macid => d.macid.upcase, 
                       :username => d.username,
                      :devicename => d.devicename,
                      :updated_at => d.updated_at,
                      :dvi => d.dvi
                    }
            r.page.list.add_row(record)
          end
       end

       report.generate_file('device_vulnerability_report.pdf')

       File.delete "#{Rails.root}/tmp/graph1.png" if File.exists? "#{Rails.root}/tmp/graph1.png"
       File.delete "#{Rails.root}/tmp/graph2.png" if File.exists? "#{Rails.root}/tmp/graph2.png"
   end

end #namespace