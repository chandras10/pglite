# == Schema Information
#
# Table name: deviceinfos
#
#  id         :integer          not null, primary key
#  macid      :string(255)
#  username   :string(255)
#  groupname  :string(255)
#  location   :string(255)
#  devicetype :string(255) - iPad/iPhone ...
#  operatingsystem  :string(255) - iOS/Android/Linux/Windows...
#  osversion  :string(255)
#  deviceclass :string(255) - MobileDevice/Desktop
#  weight     :integer
#  ipaddr     :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Deviceinfo < ActiveRecord::Base
  self.table_name = "deviceinfo"

  attr_accessible  :macid, :devicetype, :deviceclass, :groupname, :ipaddr, :location, :operatingsystem, :osversion, :username, :dvi, :weight, :created_at, :updated_at

  has_many :dvivulns, :class_name => "DviVuln", :foreign_key => "mac", :primary_key => "macid"

end
