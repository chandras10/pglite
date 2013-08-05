class Internalresourcestat < ActiveRecord::Base
  self.table_name = "internalresourcestat"
  attr_accessible :timestamp, :deviceid, :appid, :inbytes, :outbytes
  
  belongs_to :deviceinfo, :class_name => "Deviceinfo", :foreign_key => "deviceid", :primary_key => "macid"
  belongs_to :appidinternal, :class_name => "Appidinternal", :foreign_key => "appid", :primary_key => "appid"
end
