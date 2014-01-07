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

private
  
  def addLookupConditions
    return @dbTable.joins(@lookupTable).select("#{@lookupColumn} as key").
            where("#{@dbTable}.#{@destIDColumn} > 0").  # Filter out unclassified/unrated information
            group("#{@lookupColumn}") 
  end

end