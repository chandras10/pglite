class Appipinternal < ActiveRecord::Base
   self.table_name = "appipinternal"
 
   attr_accessible :iprange, :mask, :appid, :port
   belongs_to :appidinternal, :class_name => "Appidinternal", :foreign_key => "appid", :primary_key => "appid"

end
