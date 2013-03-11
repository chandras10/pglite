require 'spec_helper'

describe "Reports" do
  describe "Main Dashboard" do
    it "should have reports and graphs." do
      visit home_path
      page.should have_content('Main Dashboard')
    end
  end
end
