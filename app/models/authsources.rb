class Authsources < ActiveRecord::Base
  self.table_name = "auth_sources"

  attr_accessible :id, :description
end
