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
  establish_connection "deviceinfo_db"
  set_table_name "deviceinfo"

  attr_accessible :operatingsystem, :devicetype, :deviceclass, :groupname, :ipaddr, :location, :macid, :osversion, :username, :weight, :created_at, :updated_at
end
