class BatchReports

  @@reports = { 'dvi' => "DviReport"
              }

  def self.Report(name)
  	return nil if name.nil?

  	reportClass = @@reports[name]
  	return nil if reportClass.nil?

  	return reportClass.constantize.new
  end

  def title
  	"Unknown"
  end

end
