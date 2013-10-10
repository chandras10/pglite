class I7alertsController < ApplicationController
  before_filter :signed_in_user, only: [:index]

  def index
    @alerts = I7alert.select('timestamp, i7alertdef.id as id, i7alertdef.priority as priority, 
                              i7alertdef.description as description, i7alertclassdef.description as classtype, 
                              proto, srcmac, srcip, srcport, dstmac, dstip, dstport, pcap, message').
                      joins('LEFT OUTER JOIN i7alertdef ON i7alertdef.id = i7alert.id 
                             LEFT OUTER JOIN i7alertclassdef ON i7alertclassdef.id = i7alertdef.classid').
                      where("i7alertdef.classid NOT in (#{Rails.configuration.i7alerts_ignore_classes.join('')})")
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: I7alertsDatatable.new(view_context)}
    end
  end

end
