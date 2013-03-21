class Classdb < ActiveRecord::Base
  establish_connection "snortalert_db"
  set_table_name "classdb"

  attr_accessible :classid, :classname, :description

  #has_many :alertdb  
end
