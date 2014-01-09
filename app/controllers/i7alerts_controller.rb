class I7alertsController < ApplicationController
  before_filter :signed_in_user, only: [:index]

  def index
    set_timeLine_constants

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: I7alertsDatatable.new(view_context)}
    end
  end

  def download_pcap
    if !File.exists?(params[:filename]) then
       redirect_to '/404.html'
       return
    end
    data = File.read(params[:filename])
    send_data data, filename: File.basename(params[:filename]), type:  'application/pcap'
  end
end
