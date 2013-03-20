class Ipstat < ActiveRecord::Base
  establish_connection "stat_development"
  attr_accessible :timestamp, :deviceid, :destip, :destport, :inbytes, :outbytes
  

end
