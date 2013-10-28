class Urlcatstat < ActiveRecord::Base
  self.table_name = "urlcatstat"

  attr_accessible :timestamp, :deviceid, :id, :inbytes, :outbytes
  
  belongs_to :deviceinfo, :class_name => "Deviceinfo", :foreign_key => "deviceid", :primary_key => "macid"
  belongs_to :urlcatid, :foreign_key => "id", :primary_key => "id"
end
