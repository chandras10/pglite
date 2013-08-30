class Hostname < ActiveRecord::Base

    attr_accessible  :ip_address, :host_type, :name

    # Host_type Values are 1 => External/Internet host, 2 => Internal host
    has_many :internalipstats, :foreign_key => "destip", :primary_key => "ip_address"
    has_many :externalipstats, :foreign_key => "destip", :primary_key => "ip_address"
end
