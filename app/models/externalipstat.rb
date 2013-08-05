class Externalipstat < ActiveRecord::Base
  self.table_name = "externalipstat"

  attr_accessible :timestamp, :deviceid, :destip, :destport, :inbytes, :outbytes
  
  belongs_to :deviceinfo, :class_name => "Deviceinfo", :foreign_key => "deviceid", :primary_key => "macid"
end
