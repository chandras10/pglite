require 'bandwidth_datatable'

class BandwidthResourceDatatable < BandwidthDatatable

  def initialize(view, dbTable, destIDColumn, lookupTable, lookupColumn)
    super(view, dbTable, destIDColumn)
    @lookupTable = lookupTable.to_sym
    @lookupColumn = lookupColumn
  end

  def getDestinations
    return getDestinationsWithConditions(addLookupConditions())
  end

  def topDestinations(n)
    return topDestinationsWithConditions(addLookupConditions(), n)
  end

  def getSources
    query = @dbTable.joins(@lookupTable).select("deviceid as key, sum(inbytes) as sent, sum(outbytes) as recd, sum(inbytes) + sum(outbytes) as total").
                     group("deviceid")
    query = query.where("#{@lookupColumn} = ?", params['resource']) if params['resource'].present?
    return getSourcesWithConditions(query)
  end

  def topDestPorts(n)
    return nil if !params['resource'].present?

    query = @dbTable.joins(@lookupTable).select("#{@lookupColumn} as key").
            where("#{@dbTable}.#{@destIDColumn} > 0").  # Filter out unclassified/unrated information
            where("#{@lookupColumn} = ?", params['resource']).
            group("#{@lookupColumn}")

    return topDestPortsWithConditions(query, n)
  end

private
  
  def addLookupConditions
    query = @dbTable.joins(@lookupTable).select("#{@lookupColumn} as key").
            where("#{@dbTable}.#{@destIDColumn} > 0").  # Filter out unclassified/unrated information
            group("#{@lookupColumn}")
    query = query.where("#{@lookupColumn} = ?", params['resource']) if params['resource'].present? 
    query = query.where("#{@lookupColumn} ILIKE :search", search: "%#{params[:sSearch]}%") if (params[:sSearch].present? && !params[:sSearch].empty?)
    query
  end

end