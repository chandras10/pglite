class DeviceinfosController < ApplicationController
  # GET /deviceinfos
  # GET /deviceinfos.json
  def index
    @deviceinfos = Deviceinfo.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @deviceinfos }
    end
  end

  # GET /deviceinfos/1
  # GET /deviceinfos/1.json
  def show
    @deviceinfo = Deviceinfo.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @deviceinfo }
    end
  end

end
