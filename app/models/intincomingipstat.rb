class Intincomingipstat < ActiveRecord::Base
  self.table_name = "intincomingipstat"

  attr_accessible :timestamp, :deviceid, :destip, :destport, :inbytes, :outbytes
  
  belongs_to :deviceinfo, :class_name => "Deviceinfo", :foreign_key => "deviceid", :primary_key => "macid"
end
