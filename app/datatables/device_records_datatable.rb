class DeviceRecordsDatatable
  include DatatablesHelper
  delegate :params, :h, :link_to,  to: :@view

  def initialize(view, tableName)
    @view = view
    @tableName = tableName
  end

  def as_json(options = {})
    device = params[:device]
    if (!device.present?)
       return
    end

    case @tableName
    when "i7alerts"
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: I7alert.where("srcmac = ?", device).count,
      iTotalDisplayRecords: i7Alerts.total_entries,
      aaData: i7AlertsData
    }
    when "snort"
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Alertdb.where("srcmac = :device OR dstmac = :device", device: device).count,
      iTotalDisplayRecords: snortAlerts.total_entries,
      aaData: snortAlertsData
    }
    when "vuln"
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: DviVuln.where("mac = ?", device).count,
      iTotalDisplayRecords: vulns.total_entries,
      aaData: vulnData
    }
    when "apps"
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Browserversion.where("macid = ?", device).count,
      iTotalDisplayRecords: apps.total_entries,
      aaData: appData
    }
    when "bandwidth"
    numServers =  Externalipstat.uniq.select('destip, destport').where("deviceid = ?", params[:device]).length
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: numServers,
      iTotalDisplayRecords: numServers,
      aaData: bandwidthData      
    }      
    end
  end

private

  def i7AlertsData
    i7Alerts.map do |alert|
      {
        id: h(alert.id),
        priority: h(alert.priority),
        type: h(alert.type),
        message: h(alert.message),
        count: h(alert.count)
      }
    end
  end
  def snortAlertsData
    snortAlerts.map do |alert|
      case alert.priority
      when 1
        priority = "<center><span class='label label-important'> High </span></center>"
      when 2
        priority = "<center><span class='label label-warning'> Medium </span></center>"
      when 3
        priority = "<center><span class='label label-success'> Low </span></center>"
      when 4
        priority = "<center><span class='label label-info'> Very Low </span></center>"
      else
        priority = "<center><span class='label'> #{alert.priority} </span></center>"
      end

      snortIDLink = (!alert.message.nil? && alert.message.start_with?("ET")) ? "http://doc.emergingthreats.net/#{alert.id}" : "http://www.snort.org/search/sid/1-#{alert.id}"
      {
        id: link_to(alert.id, snortIDLink, :target => "_blank"),
        priority: priority,
        message: h(alert.message),
        count: h(alert.count)
      }
    end
  end
  def vulnData
    vulns.map do |vuln|
      score = vuln.score.to_f
      labelClass = ""
      if    score.between?(0, 3) then labelClass += " label-info"
      elsif score.between?(4, 5) then labelClass += " label-success"
      elsif score.between?(6, 9) then labelClass += " label-warning"
      elsif score == 10          then labelClass += " label-important"
      end
      vulnScore = "<center><span class=#{labelClass}>" + sprintf("%5.2f", vuln.score) + "</span></center>"
      vulnIDLink = "http://web.nvd.nist.gov/view/vuln/search-results?query=#{vuln.vuln_id}&search_type=all&cves=on"
      {
        id: link_to(vuln.vuln_id, vulnIDLink, :target => "_blank"),
        score: vulnScore,
        message: h(vuln.message),
        count: h(vuln.count)
      }
    end
  end

  def appData
    apps.map do |app|
      {
        name: app.name,
        version: app.version
      }
    end
  end

  def bandwidthData
      servers.map do |server|
        {
          server: link_to(server.destip, params.merge({:action=> "dash_bw_server", :controller=> "reports", :resource=> server.destip})),
          port: h(server.destport),
          download: h(server.download),
          upload: h(server.upload),
          total: h(server.total)
        }
      end
  end

  def i7Alerts
    alerts = I7alert.select('i7alertdef.id as id, i7alertdef.priority as priority, i7alertdef.description as type, 
                             message, count(*) as count').
                      joins('LEFT OUTER JOIN i7alertdef ON i7alertdef.id = i7alert.id 
                             LEFT OUTER JOIN i7alertclassdef ON i7alertclassdef.id = i7alertdef.classid').
                      where("i7alertdef.classid NOT in (#{Rails.configuration.i7alerts_ignore_classes.join('')})").
                      where("srcmac = ?", params[:device]).
                      group('i7alertdef.id, priority, i7alertdef.description, message')
    columns = %w[id i7alertdef.priority i7alertdef.description message count]
    alerts = alerts.order("#{columns[params[:iSortCol_0].to_i]} #{sort_direction}")
    alerts = alerts.page(page).per_page(per_page)
    alerts
  end

  def snortAlerts
    alerts = Alertdb.select("sigid as id, priority, message, count(*) as count").
                     where("(srcmac = ? OR dstmac = ?)", params[:device],  params[:device]).
                     group("sigid, priority, message")
    columns = %w[sigid priority message count]
    alerts = alerts.order("#{columns[params[:iSortCol_0].to_i]} #{sort_direction}")
    alerts = alerts.page(page).per_page(per_page)
    alerts
  end

  def vulns
    vulns = DviVuln.joins(:vulnerability).
                    select("vuln_id, vulnerability.cvss_score as score, summary as message, count(*) as count").
                    where("mac = ?", params[:device]).
                    group("vuln_id, vulnerability.cvss_score, summary")
    columns = %w[vuln_id score summary count]
    vulns = vulns.order("#{columns[params[:iSortCol_0].to_i]} #{sort_direction}")
    vulns = vulns.page(page).per_page(per_page)
    vulns
  end

  def apps
    apps = Browserversion.select("browsername as name, version").
                    where("macid = ?", params[:device])
    columns = %w[browsername version]
    apps = apps.order("#{columns[params[:iSortCol_0].to_i]} #{sort_direction}")
    apps = apps.page(page).per_page(per_page)
    apps
  end

  def servers
    servers = Externalipstat.select('destip, destport, sum(inbytes) as download, sum(outbytes) as upload, sum(inbytes)+sum(outbytes) as total').
                             where("deviceid = ?", params[:device]).
                             where("timestamp > (CURRENT_TIMESTAMP - '3 month'::interval)").
                             group('destip, destport')
    columns = %w[destip destport download upload total]
    servers = servers.order("#{columns[params[:iSortCol_0].to_i]} #{sort_direction}")
    servers = servers.page(page).per_page(per_page)
    servers
  end

end

