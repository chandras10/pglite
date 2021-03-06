class Hlurlcatstat < ActiveRecord::Base
  self.table_name = "hlurlcatstat"

  attr_accessible :timestamp, :deviceid, :id, :inbytes, :outbytes
  
  belongs_to :deviceinfo, :class_name => "Deviceinfo", :foreign_key => "deviceid", :primary_key => "macid"
  belongs_to :hlurlcatid, :foreign_key => "id", :primary_key => "id"
end
