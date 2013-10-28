class Urlcatid < ActiveRecord::Base
  self.table_name = "urlcatid"

  attr_accessible :id, :name

  has_many :urlcatstats, :class_name => "Urlcatstat", :foreign_key => "id", :primary_key => "id"
  
end