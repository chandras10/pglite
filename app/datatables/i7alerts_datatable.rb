class I7alertsDatatable
  include DatatablesHelper
  include ReportsHelper
  delegate :params, :h, :link_to,  to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: I7alert.count,
      iTotalDisplayRecords: alerts.total_entries,
      aaData: data
    }
  end

private

  def data
    timeZone = Time.zone.name

    alerts.map do |alert|
      if (!alert.pcap.nil? && !alert.pcap.empty?) then
         pcap = link_to('Packet Capture', {:action => :download_pcap, :controller => "i7alerts", :filename => h(alert.pcap)})
      else
         pcap = ''
      end
      {
        timestamp: h(alert.timestamp.in_time_zone(timeZone).strftime("%Y-%m-%d %H:%M")),
        priority: h(alert.priority),
        alerttype: h(alert.description),
        id: "<a href='#' title='" + alert.classtype + "'>#{alert.id}</a>",
        proto: h(alert.proto),
        srcmac: device_tooltip(alert.srcmac),
        srcip: h(alert.srcip),
        srcport: h(alert.srcport),
        dstmac: device_tooltip(alert.dstmac),
        dstip: h(alert.dstip),
        dstport: h(alert.dstport),
        pcap: pcap,
        message: h(alert.message)
      }
    end
  end

  def alerts
    @alerts ||= fetch_alerts
  end

  def fetch_alerts
    alerts = I7alert.select('i7alertdef.id as id, timestamp, i7alertdef.priority as priority, 
                              i7alertdef.description as description, i7alertclassdef.description as classtype, 
                              proto, srcmac, srcip, srcport, dstmac, dstip, dstport, pcap, message').
                      joins('LEFT OUTER JOIN i7alertdef ON i7alertdef.id = i7alert.id 
                             LEFT OUTER JOIN i7alertclassdef ON i7alertclassdef.id = i7alertdef.classid').
                      where("i7alertdef.classid NOT in (#{Rails.configuration.i7alerts_ignore_classes.join('')})").
                      where("i7alertdef.active = true").scoped
    alerts = setTimePeriod(alerts)
    alerts = alerts.order("#{sort_column} #{sort_direction}")
    alerts = alerts.page(page).per_page(per_page)
    if params[:sSearch].present?
      alerts = alerts.where("i7alertdef.id >= :isearch or srcmac ILIKE :search or dstmac ILIKE :search or 
                               proto >= :isearch or srcip ILIKE :search or dstip ILIKE :search or
                               srcport >= :isearch or dstport >= :isearch or message ILIKE :search", 
                               search: "%#{params[:sSearch]}%", isearch: params[:sSearch].to_i)
    end
    alerts
  end

  def sort_column
    columns = %w[timestamp i7alertdef.priority i7alertclassdef.description id proto srcmac srcip srcport dstmac dstip dstport pcap message]
    columns[params[:iSortCol_0].to_i]
  end

end

