class Hlurlcatid < ActiveRecord::Base
  self.table_name = "hlurlcatid"

  attr_accessible :id, :name

  has_many :hlurlcatstats, :class_name => "Hlurlcatstat", :foreign_key => "id", :primary_key => "id"
  
end