class DviVuln < ActiveRecord::Base
  self.table_name = "dvi_vuln"
  attr_accessible :mac, :vuln_id

  belongs_to :deviceinfo, :class_name => "Deviceinfo", :foreign_key => "mac", :primary_key => "macid"
  belongs_to :vulnerability, :class_name => "Vulnerability", :foreign_key => "vuln_id", :primary_key => "id"

end
