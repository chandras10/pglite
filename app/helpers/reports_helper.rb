module ReportsHelper
  #
  # Generate the 24 hour graph labels, showing the current hour on the right most edge and then
  # working backwards upto to 24 hours ago.
  def graphLabels24Hrs
  	currentHour = Time.now.strftime("%H").to_i 
    return (0..23).to_a.rotate(currentHour+1)
  end  
end
