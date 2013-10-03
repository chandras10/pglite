class DevicesDatatable
  delegate :params, :h, :link_to,  to: :@view

  def initialize(view)
    @view = view
    @authSources = Authsources.all    
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Deviceinfo.count,
      iTotalDisplayRecords: devices.total_entries,
      aaData: data
    }
  end

private

  def data
    devices.map do |device|
      {
        macid: link_to(device.macid, device),
        username: h(device.username),
        groupname: h(device.groupname),
        location: h(device.location),
        devicetype: h(device.devicetype),
        operatingsystem: h(device.operatingsystem),
        osversion: h(device.osversion),
        deviceclass: h(device.deviceclass),
        jailbroken: h(((device.weight & 0x00FF0000) > 0) ? "Yes" : "No"),
        dvi: h(device.dvi),
        ipaddr: h(device.ipaddr),
        created_at: h(device.created_at.strftime("%B %e, %Y")),
        updated_at: h(device.updated_at.strftime("%B %e, %Y")),
        auth_source: h(((@authSources.detect {|a| a.id == device.auth_source}).description if !@authSources.nil? ) || device.auth_source),
        devicename: h(device.devicename),
        vendorname: h(device.vendorname),
        parentmacid: h(device.parentmacid),
        "DT_RowId" =>  h(device.macid)
      }
    end
  end

  def devices
    @devices ||= fetch_devices
  end

  def fetch_devices
    devices = Deviceinfo.order("#{sort_column} #{sort_direction}")
    devices = devices.page(page).per_page(per_page)
    if params[:sSearch].present?
      devices = devices.where("macid ILIKE :search or username ILIKE :search or groupname ILIKE :search or 
                               location ILIKE :search or devicetype ILIKE :search or operatingsystem ILIKE :search or
                               deviceclass ILIKE :search or ipaddr ILIKE :search or devicename ILIKE :search or 
                               vendorname ILIKE :search", search: "%#{params[:sSearch]}%")
    end
    devices
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[macid username groupname location devicetype operatingsystem osversion deviceclass weight dvi ipaddr created_at updated_at auth_source devicename vendorname parentmacid]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end

