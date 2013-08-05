class Appidinternal < ActiveRecord::Base
   self.table_name = "appidinternal"
 
   attr_accessible :appid, :appname
   set_primary_key "appid"

end
