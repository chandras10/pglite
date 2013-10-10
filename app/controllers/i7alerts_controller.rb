class I7alertsController < ApplicationController
  before_filter :signed_in_user, only: [:index]

  def index
    @alerts = I7alert.all
    @alertdefs = I7alertdef.all
    @alertclassdefs = I7alertclassdef.all
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: I7alertsDatatable.new(view_context)}
    end
  end

end
