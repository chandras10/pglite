class DeviceinfosController < ApplicationController
  before_filter :signed_in_user, only: [:index]
  before_filter :admin_user, only: :authorize
  
  # GET /deviceinfos
  # GET /deviceinfos.json

  def index
    @authSources = Authsources.all
    @deviceinfos = Deviceinfo.all
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: DevicesDatatable.new(view_context)}
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

  def authorize
     auth_src = params[:auth_type] || 0
     Deviceinfo.update_all(["auth_source=?", auth_src], :macid => params[:ids])
     redirect_to '/tbl_inventory'
  end

end
