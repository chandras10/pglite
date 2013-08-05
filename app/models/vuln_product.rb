class VulnProduct < ActiveRecord::Base
  self.table_name = "vuln_product"
  attr_accessible :vuln_id, :product_id

  belongs_to :vulnerability, :class_name => "Vulnerability", :foreign_key => "vuln_id", :primary_key => "id"
  belongs_to :product, :class_name => "Product", :foreign_key => "product_id", :primary_key => "id"

end
