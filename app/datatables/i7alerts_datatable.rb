class I7alertsDatatable
  include DatatablesHelper
  delegate :params, :h, :link_to,  to: :@view

  def initialize(view, queryConditions)
    @view = view
    @queryConditions = queryConditions
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

    #
    # Create tooltips for each "Source Mac" found in the alerts..
    #
    devices = alerts.map {|a| a.srcmac}.uniq
    deviceHash = Hash.new
    devices.each do |d|
      deviceHash[d] = Deviceinfo.where("macid = ?", d).first
    end

    alerts.map do |alert|
      macIDTooltip = @view.render :partial=> 'layouts/tooltip_device', :formats=>[:html], :locals => {:device => deviceHash[alert.srcmac]}

      {
        timestamp: h(alert.timestamp.in_time_zone(timeZone).strftime("%Y-%m-%d %H:%M")),
        priority: h(alert.priority),
        classtype: h(alert.classtype),
        id: "<a href='#' title='" + alert.description + "'>#{alert.id}</a>",
        proto: h(alert.proto),
        srcmac: link_to(alert.srcmac, {:action=> "device_details", :controller=> "reports", :device => alert.srcmac}, {:rel => "popover", :'data-content' => "#{macIDTooltip}", :'data-original-title' => "#{alert.srcmac}" }),
        srcip: h(alert.srcip),
        srcport: h(alert.srcport),
        dstmac: h(alert.dstmac),
        dstip: h(alert.dstip),
        dstport: h(alert.dstport),
        pcap: h(alert.pcap),
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
                      where("#{@queryConditions[0][1]}").scoped
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

