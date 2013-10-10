class Deviceinfo < ActiveRecord::Base
  self.table_name = "deviceinfo"

  attr_accessible  :macid, :devicetype, :deviceclass, :groupname, :ipaddr, :location, :operatingsystem, :osversion, :username, :dvi, :weight, :created_at, :updated_at

  has_many :dvivulns, :class_name => "DviVuln", :foreign_key => "mac", :primary_key => "macid"

end
