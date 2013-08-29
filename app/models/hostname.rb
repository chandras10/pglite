class Hostname < ActiveRecord::Base
    attr_accessible  :ip_address, :name

    has_many :internalipstats, :foreign_key => "destip", :primary_key => "ip_address"
    has_many :externalipstats, :foreign_key => "destip", :primary_key => "ip_address"
end
