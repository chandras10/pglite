class I7alertsController < ApplicationController
  before_filter :signed_in_user, only: [:index]

  def index
    set_timeLine_constants

    dbQuery = I7alert
    dbQuery = addTimeLinesToDatabaseQuery(dbQuery)
    timeQueryString = dbQuery.to_sql.scan(/SELECT (.*) FROM .* WHERE\s+\((.*)\).*/i)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: I7alertsDatatable.new(view_context, timeQueryString)}
    end
  end
end
