class Ipstat < ActiveRecord::Base
  establish_connection "stat_db"
  set_table_name "ipstat"
  attr_accessible :timestamp, :deviceid, :destip, :destport, :inbytes, :outbytes
  
  belongs_to :deviceinfo, :class_name => "Deviceinfo", :foreign_key => "deviceid", :primary_key => "macid"
end