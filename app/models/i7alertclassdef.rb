class I7alertclassdef < ActiveRecord::Base
  self.table_name = "i7alertclassdef"

  attr_accessible  :id, :description

  has_many :i7alertdefs, :class_name => "I7alertdef", :foreign_key => "classid", :primary_key => "id"
end
