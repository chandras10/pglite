require 'geoip'
namespace :db do 

  task update_cc_externalip: :environment do	
     begin_time = Time.now

     geoIPconn = GeoIP.new('GeoIP.dat')
     recs = Externalipstat.select('destip').where("destip NOT like '10.%' and cc is NULL").uniq
     recs.each do |r|
      Externalipstat.where('destip = ?', r.destip).update_all(:cc => geoIPconn.country(r.destip).country_code2)
     end
     end_time = Time.now

     puts "Recs: #{recs.length} \t GeoIP Time elapsed #{(end_time - begin_time) * 1000} ms"

  end
end