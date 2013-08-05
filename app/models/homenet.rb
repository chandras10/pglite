class Homenet < ActiveRecord::Base
  self.table_name = "homenet"

  attr_accessible :net
end
