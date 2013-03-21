class ReportsController < ApplicationController
  def login
  end

  def dash_inventory
    @deviceinfos = Deviceinfo.all
  end

  def tbl_inventory
    @deviceinfos = Deviceinfo.all
  end
 
  def dash_bw
  end

  def dash_bw_server
  end

  def dash_snort
  end
end
