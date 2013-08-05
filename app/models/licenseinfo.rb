class Licenseinfo < ActiveRecord::Base
  self.table_name = "licenseinfo"

  attr_accessible :lastupdatetime, :valid_until
end
