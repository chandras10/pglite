namespace :db do
   desc "Resolving host names..."
   task resolvehostnames: :environment do

      case ENV['type']
      when "internal"
          # Using WinBIND+Samba for internal hosts
          query = Internalipstat.select("DISTINCT destip as ip").where("destip NOT IN (select ip_address from hostnames)")
          query.each do |host|
             puts host.ip
             begin
                hostname = `wbinfo --WINS-by-ip=#{host.ip} | cut -f2`.strip
                if hostname.empty? then
                   # WINBIND failed! Try DNS now...
                   hostname = dnsResolver.getname(host.ip).to_s
                end
                if !hostname.empty?
                   Hostname.create(ip_address: host.ip, host_type: 2, name: hostname)
                end
             rescue
             end
          end
      else # External DNS queries
          dnsResolver = Resolv::DNS.new
          query = Externalipstat.select("DISTINCT destip as ip").where("destip NOT IN (select ip_address from hostnames)")
          query.each do |host|
             puts host.ip
             begin
                hostname = dnsResolver.getname(host.ip).to_s
                if !hostname.empty?
                   Hostname.create(ip_address: host.ip, host_type: 1, name: hostname)
                end
             rescue
             end
          end
      end #which arg? Internal/External
   end
end