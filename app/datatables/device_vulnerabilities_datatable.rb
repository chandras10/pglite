class DeviceVulnerabilitiesDatatable
  include DatatablesHelper
  delegate :params, :h, :link_to,  to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: DviVuln.count,
      iTotalDisplayRecords: vulns.total_entries,
      aaData: data
    }
  end

private

  def data
    vulns.map do |vuln|
      score = vuln.score.to_f
      labelClass = ""
      if    score.between?(0, 3) then labelClass += " label-info"
      elsif score.between?(4, 5) then labelClass += " label-success"
      elsif score.between?(6, 9) then labelClass += " label-warning"
      elsif score == 10          then labelClass += " label-important"
      end
      vulnScore = "<span class=#{labelClass}>" + sprintf("%5.2f", vuln.score) + "</span>"
      device = Deviceinfo.exists?(:macid => vuln.mac) ? link_to(vuln.mac, :action=> "device_details", :device => vuln.mac) : vuln.mac      
      vulnIDLink = "http://web.nvd.nist.gov/view/vuln/search-results?query=#{vuln.vuln_id}&search_type=all&cves=on"

      {
        id: link_to(vuln.vuln_id, vulnIDLink, :target => "_blank"),
        device: device,
        score: vulnScore,
        date: h(vuln.date),
        summary: h(vuln.summary)
      }
    end
  end

  def vulns
    fetch_vulns
  end

  def fetch_vulns
    vulns = DviVuln.joins(:vulnerability).
                    select("mac, vuln_id, vulnerability.cvss_score as score, vulnerability.last_modify_date as date, summary")

    if (params[:device].present?) then          
        vulns = vulns.where("mac = ?", params[:device])
    end 

    vulns = vulns.order("#{sort_column} #{sort_direction}")
    vulns = vulns.page(page).per_page(per_page)
    if params[:sSearch].present?
      vulns = vulns.where("vuln_id ILIKE :search or mac ILIKE :search  or summary ILIKE :search", 
                               search: "%#{params[:sSearch]}%")
    end
    vulns
  end

  def sort_column
    columns = %w[vuln_id mac score date summary]
    columns[params[:iSortCol_0].to_i]
  end

end

