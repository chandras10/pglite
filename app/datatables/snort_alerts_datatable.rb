class SnortAlertsDatatable
  include DatatablesHelper
  delegate :params, :h, :link_to,  to: :@view

  def initialize(view, queryConditions)
    @view = view
    @queryConditions = queryConditions
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
      {
        snortID: link_to(alert.sigid, "http://www.snort.org/search/sid/1-#{alert.sigid}", :target => "_blank"),
        timestamp: h(alert.timestamp.strftime("%B %e, %Y %T")),
        message: h(alert.message),
        priority: priority,
        protocol: h(alert.protocol),
        source: "#{alert.srcip}:#{alert.srcport}",
        destination: "#{alert.destip}:#{alert.destport}",
        srcmac: h(alert.srcmac),
        dstmac: h(alert.dstmac)
      }
    end
  end

  def alerts
    fetch_alerts
  end

  def fetch_alerts
    if (params[:device].present?) then          
        alerts = Alertdb.select("timestamp, priority, sigid, message, protocol, 
                                             srcip, srcport, destip, destport, srcmac, dstmac").
                                     where("#{@queryConditions[0][1]} and (srcmac = ? OR dstmac = ?)", params[:device],  params[:device])
    else
        alerts = Alertdb.select("timestamp, priority, sigid, message, protocol, 
                                             srcip, srcport, destip, destport, srcmac, dstmac").
                                     where("#{@queryConditions[0][1]}")
    end    
    alerts = alerts.order("#{sort_column} #{sort_direction}")
    alerts = alerts.page(page).per_page(per_page)
    if params[:sSearch].present?
      alerts = alerts.where("sigid ILIKE :search or message ILIKE :search or protocol ILIKE :search or 
                               srcip ILIKE :search or srcport ILIKE :search or destip ILIKE :search or
                               destport ILIKE :search or srcmac ILIKE :search or dstmac ILIKE :search", 
                               search: "%#{params[:sSearch]}%")
    end
    alerts
  end

  def sort_column
    columns = %w[sigid timestamp message priority protocol srcip destip srcmac dstmac]
    columns[params[:iSortCol_0].to_i]
  end

end

