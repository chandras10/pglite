class Browserversion < ActiveRecord::Base
  establish_connection "deviceinfo_db"
  set_table_name "browserversion"

  attr_accessible :macid, :browsername, :version
  
  belongs_to :deviceinfo, :class_name => "Deviceinfo", :foreign_key => "macid", :primary_key => "macid"
end
