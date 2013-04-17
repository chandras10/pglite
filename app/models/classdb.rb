class Classdb < ActiveRecord::Base
  self.table_name = "classdb"

  attr_accessible :classid, :classname, :description

  #has_many :alertdb  
end
