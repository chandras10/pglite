class SnortAlertsDatatable
  include DatatablesHelper
  include ReportsHelper
  delegate :params, :h, :link_to,  to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Alertdb.count,
      iTotalDisplayRecords: alerts.total_entries,
      aaData: data
    }
  end

private

  def data
    timeZone = Time.zone.name

    alerts.map do |alert|
      case alert.priority
      when 1
        priority = "<span class='label label-important'> High </span>"
      when 2
        priority = "<span class='label label-warning'> Medium </span>"
      when 3
        priority = "<span class='label label-success'> Low </span>"
      when 4
        priority = "<span class='label label-info'> Very Low </span>"
      else
        priority = "<span class='label'> #{alert.priority} </span>"
      end

      snortIDLink = (!alert.message.nil? && alert.message.start_with?("ET")) ? "http://doc.emergingthreats.net/#{alert.sigid}" : "http://www.snort.org/search/sid/1-#{alert.sigid}"

      {
        snortID: link_to(alert.sigid, snortIDLink, :target => "_blank"),
        timestamp: h(alert.timestamp.in_time_zone(timeZone).strftime("%Y-%m-%d %H:%M")),
        message: h(alert.message),
        priority: priority,
        protocol: h(alert.protocol),
        source: "#{alert.srcip}:#{alert.srcport}",
        destination: "#{alert.destip}:#{alert.destport}",
        srcmac: device_tooltip(alert.srcmac),
        dstmac: device_tooltip(alert.dstmac)
      }
    end
  end

  def alerts
    fetch_alerts
  end

  def fetch_alerts
    alerts = Alertdb.select("timestamp, priority, sigid, message, protocol, 
                                             srcip, srcport, destip, destport, srcmac, dstmac")
    alerts = setTimePeriod(alerts)

    if (params[:device].present?) then          
        alerts = alerts.where("(srcmac = ? OR dstmac = ?)", params[:device],  params[:device])
    end 

    if (params[:sigid].present?) then          
        alerts = alerts.where("sigid = ?", params[:sigid])
    end 

    alerts = alerts.order("#{sort_column} #{sort_direction}")
    alerts = alerts.page(page).per_page(per_page)
    if params[:sSearch].present?
      alerts = alerts.where("sigid >= :isearch or message ILIKE :search or protocol >= :isearch or 
                               srcip ILIKE :search or srcport >= :isearch or destip ILIKE :search or
                               destport >= :isearch or srcmac ILIKE :search or dstmac ILIKE :search", 
                               search: "%#{params[:sSearch]}%", isearch: params[:sSearch].to_i)
    end
    alerts
  end

  def sort_column
    columns = %w[sigid timestamp message priority protocol srcip destip srcmac dstmac]
    columns[params[:iSortCol_0].to_i]
  end

end

