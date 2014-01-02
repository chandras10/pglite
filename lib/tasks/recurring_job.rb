class RecurringJob
  include ScheduledJob

  def initialize
  	@run_interval = 2.minute
  end

  def perform
    ActiveRecord::Base.connection.execute("update test_job set last_update = CURRENT_TIMESTAMP")
  end
end