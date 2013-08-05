class Appidexternal < ActiveRecord::Base
  self.table_name = "appidexternal"
  set_primary_key "appid"

  attr_accessible :appid, :appname
end
