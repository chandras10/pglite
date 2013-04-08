class Classdb < ActiveRecord::Base
  establish_connection "snortalert_db"
  self.table_name = "classdb"

  attr_accessible :classid, :classname, :description

  #has_many :alertdb  
end
