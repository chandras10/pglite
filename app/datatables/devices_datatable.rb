class DevicesDatatable
  include DatatablesHelper
  delegate :params, :h, :link_to,  to: :@view

  def initialize(view)
    @view = view
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
    timeZone = Time.zone.name

    devices.map do |device|
      {
        macid: link_to(device.macid, :action=> "device_details", :controller=> "reports", :device => device.macid),
        username: h(device.username),
        groupname: h(device.groupname),
        location: h(device.location),
        devicetype: h(device.devicetype),
        operatingsystem: h(device.operatingsystem),
        osversion: h(device.osversion),
        deviceclass: h(device.deviceclass),
        jailbroken: h(((device.weight & 0x00FF0000) > 0) ? "Yes" : "No"),
        dvi: h(device.dvi),
        dti: h(device.dti),
        ipaddr: h(device.ipaddr),
        created_at: h(device.created_at.in_time_zone(timeZone).strftime("%Y-%m-%d %H:%M")),
        updated_at: h(device.updated_at.in_time_zone(timeZone).strftime("%Y-%m-%d %H:%M")),
        auth_source: h(device.description),
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
    devices = Deviceinfo.select("#{columns.join(', ')}")
    devices = devices.joins('LEFT OUTER JOIN auth_sources ON id = auth_source')
    devices = devices.order("#{sort_column} #{sort_direction}")

    if params[:column].present? and params[:value].present?
       devices = devices.where("#{params[:column]} = '"+ params[:value] + "'")
    end
    
    devices = devices.page(page).per_page(per_page)
    if params[:sSearch].present?
      devices = devices.where("macid ILIKE :search or username ILIKE :search or groupname ILIKE :search or 
                               location ILIKE :search or devicetype ILIKE :search or operatingsystem ILIKE :search or
                               deviceclass ILIKE :search or ipaddr ILIKE :search or devicename ILIKE :search or 
                               auth_sources.description ILIKE :search or vendorname ILIKE :search", 
                               search: "%#{params[:sSearch]}%")
    end
    devices
  end

  def columns
      %w[macid username groupname location devicetype operatingsystem osversion deviceclass weight dvi dti ipaddr created_at updated_at auth_sources.description devicename vendorname parentmacid]
  end

  def sort_column
    columns[params[:iSortCol_0].to_i]
  end

end

