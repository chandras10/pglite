class BatchReports

  @@reports = { 'dvi' => {generator: "DviReport", title: "DVI Report"}
              }

  def self.Report(name)
  	return nil if name.nil?

  	type = @@reports[name] && @@reports[name][:generator]
  	return nil if type.nil?

  	return type.constantize.new(@@reports[name][:title])
  end

end
