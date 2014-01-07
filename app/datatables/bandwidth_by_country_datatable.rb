class BandwidthByCountryDatatable
  include DatatablesHelper
  include ReportsHelper
  delegate :params, :h, :link_to,  to: :@view

  def initialize(view, timeCondition)
    @view = view
    @timeCondition = timeCondition[0][1]
  end

  def as_json(options = {})
    numServers =  Externalipstat.uniq.select('destip, destport').where("#{@timeCondition} and cc = ?", params[:country]).length
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: numServers,
      iTotalDisplayRecords: numServers,
      aaData: data
    }
  end

private

  def data
    paramHash = {}
    paramHash[:action] = "dash_bw_server"
    paramHash[:controller] = "reports"
    paramHash[:reportType] = "externalIP"
    if params.has_key?(:reportTime) then
       paramHash[:reportTime] = params[:reportTime]
       if params[:reportTime] == "date_range" then
          paramHash[:fromDate] = params[:fromDate]
          paramHash[:toDate] = params[:toDate]
       end
    end

    servers.map do |rec|
      {
        server: link_to(rec.server, paramHash.merge({:resource=> rec.server})),
        port: h(rec.port),
        upload: h(rec.upload.to_i/$BW_MEASURE),
        download: h(rec.download.to_i/$BW_MEASURE),
        total: h(rec.total.to_i/$BW_MEASURE),
        "DT_RowId" =>  h(rec.server)
      }
    end
  end

  def servers
    fetch_servers
  end

  def fetch_servers
    servers = Externalipstat.select('destip as server, destport as port, sum(inbytes) as download, sum(outbytes) as upload, sum(inbytes)+sum(outbytes) as total').group('destip, destport')
    servers = servers.order("#{sort_column} #{sort_direction}")
    servers = servers.page(page).per_page(per_page)
    servers = servers.where("#{@timeCondition} and cc = ?", params[:country])

    if params[:sSearch].present?
      servers = servers.where("destip ILIKE :search", search: "%#{params[:sSearch]}%")
    end
    servers
  end

  def sort_column
    columns = %w[server port upload download total]
    columns[params[:iSortCol_0].to_i]
  end

end

