require 'spec_helper'

describe "UserPages" do
  describe "Login Page" do
    it "should have username and password fields." do
      visit login_path
      page.should have_content('Please login with your Username and Password.')
    end
  end
end
