class I7alert < ActiveRecord::Base
  self.table_name = "i7alert"

  attr_accessible  :timestamp, :id, :srcmac, :dstmac, :proto, :srcip, :dstip, :srcport, :dstport, :pcap, :message

  belongs_to :i7alertdef, :class_name => "I7alertdef", :foreign_key => "id", :primary_key => "id"  
end
