class Product < ActiveRecord::Base
  self.table_name = "product"

  attr_accessible :id, :os_name

  has_many :vuln_products, :class_name => "VulnProduct", :foreign_key => "product_id"

end
