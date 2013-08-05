class Externalresourcestat < ActiveRecord::Base
  self.table_name = "externalresourcestat"

  attr_accessible :timestamp, :deviceid, :appid, :inbytes, :outbytes
  
  belongs_to :deviceinfo, :class_name => "Deviceinfo", :foreign_key => "deviceid", :primary_key => "macid"
  belongs_to :appidexternal, :class_name => "Appidexternal", :foreign_key => "appid", :primary_key => "appid"
end
