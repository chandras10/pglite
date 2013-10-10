class I7alertdef < ActiveRecord::Base
  self.table_name = "i7alertdef"

  attr_accessible  :id, :priority, :classid, :description

  belongs_to :i7alertclassdef, :class_name => "I7alertclassdef", :foreign_key => "classid", :primary_key => "id"
  has_many :i7alerts, :class_name => "I7alert", :foreign_key => "id", :primary_key => "id"
end
