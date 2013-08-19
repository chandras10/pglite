module DviReportHelper

require 'thinreports'
  
    TRUNCATE_MESG_LENGTH = 400
    VULN_SEVERITY_LABELS = ["CRITICAL", "HIGH", "MEDIUM", "LOW", ""]
    DVI_SEVERITY_LABELS = ["Low", "Medium", "High"]
    DVI_SEVERITY_RANGES = [0.0..0.39, 0.4..0.69, 0.7..1.0]

    def dviReport
          @reportGenTimeStamp = Time.now.strftime('%Y%m%d_%H%M%S')
          @reportFileName = "dvi_report_" + @reportGenTimeStamp

          dvi_report = ThinReports::Report.create do |r|
             @report = r
             r.use_layout "#{Rails.root}/app/reports/dvi_chart.tlf", :id => :dvi_chart
             r.use_layout "#{Rails.root}/app/reports/dvi_table.tlf", :id => :dvi_table
             r.use_layout "#{Rails.root}/app/reports/dvi_vuln_by_os.tlf", :id => :vuln_by_os_summary
             r.use_layout "#{Rails.root}/app/reports/dvi_vuln_by_os_osver_table.tlf", :id => :vuln_by_os_osver_table


             r.events.on :page_create do |e|
                e.page.item(:page_number).value(e.page.no)
                e.page.item(:report_create_date).value(Time.now)
             end


             #DATABASE QUERIES
             @deviceList = Deviceinfo.
                               select("macid, username, devicename, operatingsystem, osversion, weight, to_char(updated_at, 'YYYY-MM-DD HH') as updated_at, dvi, weight").
                               where("ipaddr <> '' ").
                               order("dvi DESC")
             @deviceVulns =  DviVuln.joins(:deviceinfo).joins(:vulnerability).
                                 select("deviceinfo.macid as mac, deviceinfo.operatingsystem as os, deviceinfo.osversion as osver, vuln_id, 
                                         vulnerability.summary as desc, vulnerability.cvss_score as score, vulnerability.cvss_access_complexity as vuln_severity")

             @snortAlerts = Alertdb.select("srcmac, dstmac, sigid, priority, message, count(*) as cnt").group("srcmac, dstmac, sigid, priority, message")

             @prodVulns = Product.find_by_sql("select p.os_name as os, p.os_version as osver, v.cvss_access_complexity as severity, count(v.id) as cnt 
                                               from product p, vulnerability v, vuln_product vp 
                                               where lower(p.os_name) in (SELECT distinct lower(operatingsystem) from deviceinfo)  AND
                                                     lower(p.os_version) in (SELECT distinct lower(osversion) from deviceinfo) AND 
                                                     vp.vuln_id = v.id AND vp.product_id = p.id 
                                               group by p.os_name, p.os_version, v.cvss_access_complexity 
                                               order by os, osver, v.cvss_access_complexity")

             r.start_new_page :layout => :dvi_chart
           
             setCompanyDetails()             
             printDVILegend()


             dviSeverityGraph()

             r.start_new_page :layout => :dvi_table
             dviTableListingAllDevices()

             # 
             #----------------------------------------
             #
             r.start_new_page :layout => :vuln_by_os_summary
             vulnByOsGraph()

             r.start_new_page :layout => :vuln_by_os_osver_table
             vulnByOs_OsversionTable()
             
          end # report.create

       return dvi_report

    end

    def dviIndex(dviScore)
        return DVI_SEVERITY_RANGES.index(DVI_SEVERITY_RANGES.detect {|r| r.include?(dviScore)} ) 
    end

	  def setCompanyDetails
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

          @report.page.values(:company_name       => page1_header[:company_name],
                             :company_addr_line1 => page1_header[:company_addr_line1],
                             :company_addr_line2 => page1_header[:company_addr_line2],
                             :company_addr_line3 => page1_header[:company_addr_line3])
    end

    def printDVILegend
          list = @report.page.list(:dvi_score_legend)
          i=0
          DVI_SEVERITY_RANGES.each do |r|
             list.add_row({:dvi_range => r.to_s.sub("..", " - "), :severity_label => DVI_SEVERITY_LABELS[i]})
             i += 1
          end
    end

    def dviSeverityGraph
       dvi_counter = Array.new(3, 0)
       devicesWithSeverity = Hash.new
         
       @deviceList.each do |d|
          n = dviIndex(d.dvi)
          next if n.nil?

          dvi_counter[n] += 1

          devicesWithSeverity[n] = Array.new if devicesWithSeverity[n].nil?
          devicesWithSeverity[n] << d
       end # foreach device

       #
       # DVI graph showing device list sliced by DVI severity (HIGH/MED/LOW)
       #
       g = Gruff::SideBar.new
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

       graphLabelHash = Hash.new
       DVI_SEVERITY_LABELS.each_with_index do |label, i|
          dataArray = Array.new(DVI_SEVERITY_LABELS.length, 0)
          dataArray[i] = dvi_counter[i]

          g.data(label, dataArray)

          graphLabelHash[i] = label
       end

       g.minimum_value = 0
       g.marker_count = 3

       g.labels = graphLabelHash

       graphFile = "#{@tmpDir}/dvi_severity_graph.png" 
       g.write graphFile

       @report.page.values(:graph1_title => "Device Vulnerability Index (DVI)")
       @report.page.item(:graph1).src(graphFile) if File.exists? graphFile

       DVI_SEVERITY_LABELS.each_with_index do |label, sevIndex|
          @report.page.list(:top3_list).add_row dvi_severity: label do |row|
              1.upto(8) { |n| row.item("col_border#{n}".to_sym).hide }                   
          end

          next if devicesWithSeverity[sevIndex].nil?

          #Print top 3 devices for each DVI severity
          devicesWithSeverity[sevIndex][0..2].each_with_index do |d, n|
             vulns = @deviceVulns.select {|dv| dv.mac == d.macid }
             snorts = @snortAlerts.select {|sa| (sa.srcmac == d.macid || sa.dstmac == d.macid) }

             @report.page.list(:top3_list).add_row do |row|
                 row.item(:sl_no).value("#{n+1}.")
                 row.item(:macid).value(d.macid.upcase)
                 row.item(:username).value(d.username)
                 row.item(:devicename).value(d.devicename)
                 row.item(:os).value("#{d.operatingsystem} #{d.osversion}")
                 row.item(:compromised).value(((d.weight & 0x00FF0000) > 0) ? "Yes" : "No")
                 row.item(:ids_count).value(snorts.uniq {|sa| sa.sigid}.count)
                 row.item(:vuln_count).value(vulns.uniq {|v| v.vuln_id}.count)
                 row.item(:dvi).value(d.dvi)
             end
          end 
       end# for each DVI severity label
    end

    def dviTableListingAllDevices
          @deviceList.each_with_index do |d, i|
            vulns = @deviceVulns.select {|dv| dv.mac == d.macid }
            snorts = @snortAlerts.select {|sa| (sa.srcmac == d.macid || sa.dstmac == d.macid) }
            
            @report.page.list.add_row( { :line_no => "#{i+1}.",
                                   :macid => d.macid.upcase, 
                                   :username => d.username,
                                   :devicename => d.devicename,
                                   :os => "#{d.operatingsystem} #{d.osversion}",
                                   :compromised => ((d.weight & 0x00FF0000) > 0) ? "Yes" : "No", 
                                   :ids_count => snorts.uniq {|sa| sa.sigid}.count, 
                                   :vuln_count => vulns.uniq {|v| v.vuln_id}.count,
                                   :dvi => "#{d.dvi.round(2)}"
                                 })

            # TODO: Color rows different if there is a jailbroken device - d.weight & 0x00FF0000 > 0
          end
    end

    def vulnByOsGraph
       
       severityLabelHash = Hash[VULN_SEVERITY_LABELS.map.with_index.to_a]

       @report.page.values(:graph_title => "Vulnerabilities By Operating System")

       g = Gruff::Pie.new
       g.hide_title
       g.theme_37signals

       osVulnHash = Hash.new
       osList = @deviceVulns.map {|dv| dv.os}.uniq.sort
       osList.each do |os|
          deviceVulnRecs = @deviceVulns.select{|dv| dv.os == os}
          osVersionList = deviceVulnRecs.map {|dv| dv.osver.to_s}.uniq.sort
         
          osVulnHash[os] = Array.new(VULN_SEVERITY_LABELS.length, 0) if osVulnHash[os].nil?
          deviceCount = deviceVulnRecs.map{|dv| dv.mac}.uniq.count

          osVersionList.each do |osver|
             prodVulnRecs = @prodVulns.select {|pv| pv.os.downcase == os.downcase && pv.osver.downcase == osver.downcase}
             prodVulnRecs.each do |rec|
                osVulnHash[os][severityLabelHash[rec.severity.to_s]] += rec.cnt.to_i
             end
          end

          totalVulnCount = osVulnHash[os].inject(:+)
          g.data os, totalVulnCount

          @report.page.list.add_row do |row|
              row.item(:operatingsystem).value(os)
              row.item(:device_count).value(deviceCount)
              row.item(:high_vuln_count).value(osVulnHash[os][severityLabelHash["HIGH"]])
              row.item(:medium_vuln_count).value(osVulnHash[os][severityLabelHash["MEDIUM"]])
              row.item(:low_vuln_count).value(osVulnHash[os][severityLabelHash["LOW"]])
              row.item(:total_vuln_count).value(totalVulnCount)
          end
       end #for each OS

       graphFile = "#{@tmpDir}/vuln_by_os_graph.png" 
       g.write graphFile
       @report.page.item(:graph).src(graphFile) if File.exists? graphFile

    end

    def vulnByOs_OsversionTable
       severityLabelHash = Hash[VULN_SEVERITY_LABELS.map.with_index.to_a]

       osVulnHash = Hash.new
       osList = @deviceVulns.map {|dv| dv.os}.uniq.sort
       osList.each do |os|
          @report.page.list.add_row({:os_name => os})

          deviceVulnRecs = @deviceVulns.select{|dv| dv.os == os}
          osVersionList = deviceVulnRecs.map {|dv| dv.osver.to_s if dv.os == os}.uniq.sort
          osVersionList.each do |osver|         
             osVulnHash[osver] = Array.new(VULN_SEVERITY_LABELS.length, 0) if osVulnHash[osver].nil?
             deviceCount = deviceVulnRecs.map{|dv| dv.mac if dv.osver == osver}.uniq.count

             prodVulnRecs = @prodVulns.select {|pv| pv.os.downcase == os.downcase && pv.osver.downcase == osver.downcase}
             prodVulnRecs.each do |rec|
                osVulnHash[osver][severityLabelHash[rec.severity.to_s]] += rec.cnt.to_i
             end

             @report.page.list.add_row do |row|
                row.item(:os_version).value(osver.empty? ? "Unknown" : osver)
                row.item(:device_count).value(deviceCount)
                row.item(:high_vuln_count).value(osVulnHash[osver][severityLabelHash["HIGH"]])
                row.item(:medium_vuln_count).value(osVulnHash[osver][severityLabelHash["MEDIUM"]])
                row.item(:low_vuln_count).value(osVulnHash[osver][severityLabelHash["LOW"]])
                row.item(:total_vuln_count).value(osVulnHash[osver].inject(:+))
             end
          end #for each OS version
       end #for each OS
    end
end