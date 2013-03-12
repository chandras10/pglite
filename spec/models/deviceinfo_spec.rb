# == Schema Information
#
# Table name: deviceinfos
#
#  id         :integer          not null, primary key
#  macid      :string(255)
#  username   :string(255)
#  groupname  :string(255)
#  location   :string(255)
#  devicename :string(255)
#  classname  :string(255)
#  osversion  :string(255)
#  devicetype :string(255)
#  weight     :integer
#  ipaddr     :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe Deviceinfo do
  pending "add some examples to (or delete) #{__FILE__}"
end
