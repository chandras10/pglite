module ReportsHelper
  #
  # Generate the 24 hour graph labels, showing the current hour on the right most edge and then
  # working backwards upto to 24 hours ago.
  def graphLabels24Hrs
#  	currentHour = Time.now.strftime("%H").to_i 
  	labelArray = (0..23).to_a #.rotate(currentHour+1)
  	labelArray.map! do |i|
  		if (i%2 == 0) then
  		   if (i < 12) then
  			  "%02d:00 AM" % i
  		   elsif (i == 12) then
  			  "12:00 PM"
  		   else
  			 "%02d:00 PM" % (i - 12)
  		   end
  		end
  	end
  end  

  #
  # Bandwidth data will be shown in M/K/bytes depending on the variable value below.
  #  2 ** 0 = one byte; 1K = 2 ** 10;  1M = 2 ** 20
  # 
  $BW_MEASURE = 2 ** 10

  def bandwidth_label
      label = "(bytes)"
      if ($BW_MEASURE > 1000000) then
         label = "(Mbytes)"
      elsif ($BW_MEASURE > 1000) then
         label = "(Kbytes)"
      end
  end

end
