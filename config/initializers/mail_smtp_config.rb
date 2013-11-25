ActionMailer::Base.smtp_settings = {
  :address       => 'smtp.gmail.com',
  :port          => 587,
  :domain        => 'gmail.com',
  :user_name     => 'chandrashekar.m@gmail.com',
  :password      => 'g00glepers0n@l',
  :authentication=> 'plain',
  :enable_starttls_auto => true
}