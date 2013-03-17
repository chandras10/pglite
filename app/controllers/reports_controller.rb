class ReportsController < ApplicationController
  def login
  end

  def dash_inventory
    @deviceinfos = Deviceinfo.all 

    # DeviceName examples: Windows Phone, iPad, iPhone, etc;
    @deviceNameCounters = Deviceinfo.find(:all,
                              :select => 'devicename as label, count(*) as data',
                              :group  => 'devicename')

    @deviceNameLabels = @deviceNameCounters.map do |d|
                                                  d.label
                                                end

    @deviceNameData = @deviceNameCounters.map do |d|
                                                  d.data
                                                end


    @OsCounters = Deviceinfo.find(:all,
                              :select => 'classname, count(*) as data', 
                              :group  => 'classname')

    @OsLabels = @OsCounters.map do |d|
                                  d.classname
                                end
    @OsData = @OsCounters.map do |d|
                                  d.data
                                end

    respond_to do | format |
      format.html
      format.json { render  :json => @deviceinfos }
    end
  end

  def tbl_inventory
    @deviceinfos = Deviceinfo.all 
  end
 
  def dash_bw
  end
end
