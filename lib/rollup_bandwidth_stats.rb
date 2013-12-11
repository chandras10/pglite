class RollupBandwidthStats
  def perform

  end

  def daywiseRollup(date)
    recs = Internalipstat.select("date_trunc('day', timestamp) as day, deviceid, destip, destport, sum(inbytes) as inbytes, sum(outbytes) as outbytes").
                          group(:day, :deviceid, :destip, :destport).
                          having("date_trunc('day', timestamp) <= '#{date}' AND date_trunc('day', timestamp) >= date '#{date}' - 1")

    insertValues = recs.map { |r| "('#{r.day}', '#{r.deviceid}', '#{r.destip}', #{r.destport}, #{r.inbytes}, #{r.outbytes})"}.join(", ")
    insertStmt  = "INSERT INTO internalipstat (timestamp, deviceid, destip, destport, inbytes, outbytes) VALUES #{insertValues}"

    ActiveRecord::Base.transaction do
      Internalipstat.delete_all("date_trunc('day', timestamp) <= '#{date}' AND date_trunc('day', timestamp) >= date '#{date}' - 1")
      ActiveRecord::Base.connection.execute insertStmt
    end
  end

  def monthwiseRollup(date)
    recs = Internalipstat.select("date_trunc('month', timestamp) as day, deviceid, destip, destport, sum(inbytes) as inbytes, sum(outbytes) as outbytes").
                          group(:day, :deviceid, :destip, :destport).
                          having("date_trunc('month', timestamp) <= '#{date}'")

    insertValues = recs.map { |r| "('#{r.day}', '#{r.deviceid}', '#{r.destip}', #{r.destport}, #{r.inbytes}, #{r.outbytes})"}.join(", ")
    insertStmt  = "INSERT INTO internalipstat (timestamp, deviceid, destip, destport, inbytes, outbytes) VALUES #{insertValues}"

    ActiveRecord::Base.transaction do
      Internalipstat.delete_all("date_trunc('month', timestamp) <= '#{date}'")
      ActiveRecord::Base.connection.execute insertStmt
    end
  end

end