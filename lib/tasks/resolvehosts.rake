namespace :db do
   desc "Resolving host names..."
   task resolvehostnames: :environment do
       dnsResolver = Resolv::DNS.new

       tables = [Internalipstat.select("DISTINCT destip as ip"), Externalipstat.select("DISTINCT destip as ip")]

       tables.each do |query|
          query.each do |host|
             puts host.ip
             begin
                hostname = dnsResolver.getname(host.ip).to_s
                if !hostname.empty?
                   Hostname.create(ip_address: host.ip, name: hostname)
                end
             rescue
             end
          end
       end #for each database query
   end
end