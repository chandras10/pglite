class ReportsController < ApplicationController
  def login
  end

  def inventory_dashboard
    @deviceinfos = Deviceinfo.all 
  end

  def inventory_table
    @deviceinfos = Deviceinfo.all 
  end
end
