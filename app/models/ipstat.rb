class Ipstat < ActiveRecord::Base
  establish_connection "stat_db"
  attr_accessible :timestamp, :deviceid, :destip, :destport, :inbytes, :outbytes
  

end
