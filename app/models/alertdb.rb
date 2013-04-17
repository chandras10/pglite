class Alertdb < ActiveRecord::Base

  self.table_name = "alertdb"
  attr_accessible :timestamp, :eventid, :srcmac, :dstmac, :protocol, :srcip, :srcport, :destip, :destport, :sigid, :sigrev, :classid, :priority, :message
  
  #
  # Right now, in the UI we will only display Snort alerts wherein the "device" is the originator. 
  # Most of the backend code of PG is also looking at "src MAC" only. If the "device" is being attacked, then the 
  # assumption here is that there could other devices in the network which are taking care of dropping those packets before it
  # reaches the device.
  # 
  belongs_to :deviceinfo, :class_name => "Deviceinfo", :foreign_key => "srcmac", :primary_key => "macid"
end
