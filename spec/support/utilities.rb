def full_title(page_title)
  base_title = "Peregine Guard"
  if page_title.empty?
    base_title
  else
    "#{base_title} | #{page_title}"
  end
end

def sign_in(user)
	visit signin_path
	fill_in "Name", with: user.name
    fill_in "Password", with: user.password
    click_button "Login"
    cookies[:remember_token] = user.remember_token
end
