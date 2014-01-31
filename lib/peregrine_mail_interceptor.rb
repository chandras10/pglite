class PeregrineMailInterceptor
  def self.delivering_email(message)
  	config = ActionMailer::Base.smtp_settings

    message.from = config[:user_name] if !config[:user_name].blank?
    message.to = config[:to] if !config[:to].blank?
    message.cc = config[:cc] if !config[:cc].blank?

#    Rails.logger.debug "CHANDRA: #{ActionMailer::Base.smtp_settings}"
  end
end

