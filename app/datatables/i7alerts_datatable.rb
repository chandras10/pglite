class I7alertsDatatable
  delegate :params, :h, :link_to,  to: :@view

  def initialize(view)
    @view = view
    @alertdefs = I7alertdef.all
    @alertclassdefs = I7alertclassdef.all
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
    alerts.map do |alert|
      alertdef = @alertdefs.detect {|x| x.id == alert.id}
      alertclassdef = @alertclassdefs.detect{|x| x.id == alertdef.classid} if !alertdef.nil?
      {
        timestamp: h(alert.timestamp.strftime("%B %e, %Y %T")),
        priority: h((!alertdef.nil?) ? alertdef.priority : ""),
        classname: h((!alertclassdef.nil?) ? alertclassdef.description : ""),
        id: "<a href='#' title='" + (!alertdef.nil? ? alertdef.description : "") + "'>#{alert.id}</a>",
        proto: h(alert.proto),
        srcmac: h(alert.srcmac),
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
    alerts = I7alert.order("#{sort_column} #{sort_direction}")
    alerts = alerts.page(page).per_page(per_page)
    if params[:sSearch].present?
      alerts = alerts.where("id ILIKE :search or srcmac ILIKE :search or dstmac ILIKE :search or 
                               proto ILIKE :search or srcip ILIKE :search or dstip ILIKE :search or
                               srcport ILIKE :search or dstport ILIKE :search or message ILIKE :search", 
                               search: "%#{params[:sSearch]}%")
    end
    alerts
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[timestamp priority classname id srcmac dstmac proto srcip srcport dstip dstport pcap message]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end

