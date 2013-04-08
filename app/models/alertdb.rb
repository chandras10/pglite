class Alertdb < ActiveRecord::Base
  establish_connection "snortalert_db"
  #set_table_name "alertdb"

  self.table_name = "alertdb"
  attr_accessible :timestamp, :eventid, :srcmac, :dstmac, :protocol, :srcip, :srcport, :destip, :destport, :sigid, :sigrev, :classid, :priority, :message
  
  belongs_to :classdb
end
