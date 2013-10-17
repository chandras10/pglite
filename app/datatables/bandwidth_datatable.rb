class BandwidthDatatable
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
    servers.map do |rec|
      {
        server: link_to(rec.server, params.merge({:action=> "dash_bw_server", :controller=> "reports", :resource=> rec.server})),
        port: h(rec.port),
        upload: h(rec.upload),
        download: h(rec.download),
        total: h(rec.total),
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
    servers = servers.where("destip NOT like '10.%' and #{@timeCondition} and cc = ?", params[:country])

    if params[:sSearch].present?
      servers = servers.where("destip ILIKE :search", search: "%#{params[:sSearch]}%")
    end
    servers
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[server port upload download total]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end

