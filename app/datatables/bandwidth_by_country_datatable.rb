class BandwidthByCountryDatatable
  include DatatablesHelper
  include ReportsHelper
  include ActionView::Helpers::NumberHelper  #using the number_to_human_size function call...

  delegate :params, :h, :link_to,  to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    numServers =  Externalipstat.uniq.select('destip, destport').where("cc = ?", params[:country])
    numServers = setTimePeriod(numServers).length
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
        upload: h(number_to_human_size rec.upload),
        download: h(number_to_human_size rec.download),
        total: h(number_to_human_size rec.total),
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
    servers = servers.where("cc = ?", params[:country])
    servers = setTimePeriod(servers)

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

