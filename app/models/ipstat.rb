class Ipstat < ActiveRecord::Base
  establish_connection "stat_db"
  set_table_name "ipstat"
  attr_accessible :timestamp, :deviceid, :destip, :destport, :inbytes, :outbytes
  

end