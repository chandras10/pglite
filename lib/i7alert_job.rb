class I7alertJob < Struct.new(:macids)
  def perform
    if macids.nil? || macids.empty?
       return
    end

    macIDs = I7alert.where("id IN (#{macids})").pluck('srcmac').uniq
    if (macIDs.empty?)
       return
    end

    ActiveRecord::Base.transaction do
      I7alert.delete_all("id IN (#{macids})")
      macIDs.each do |device|
        ActiveRecord::Base.connection.execute("SELECT * FROM computeDVI('#{device}')")
        ActiveRecord::Base.connection.execute("SELECT * FROM computeDTI('#{device}')")
      end
    end

  end
end