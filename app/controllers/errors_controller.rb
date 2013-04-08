class ErrorsController < ApplicationController

  def internal_error
  	@status      = env["PATH_INFO"][1..-1]
  	@exception    = env["action_dispatch.exception"]  	
  end

end