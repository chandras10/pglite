require 'spec_helper'

describe "Reports" do
  describe "Main Dashboard" do
    it "should have reports and graphs." do
      visit root_path
      page.should have_content('Sign in')
    end
  end
end
