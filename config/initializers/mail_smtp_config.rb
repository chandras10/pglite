ActionMailer::Base.smtp_settings = {
  :address       => 'smtp.gmail.com',
  :port          => 587,
  :domain        => 'gmail.com',
  :user_name     => 'someone@gmail.com',
  :password      => 'xxxxxxxx',
  :authentication=> 'plain',
  :enable_starttls_auto => true
}