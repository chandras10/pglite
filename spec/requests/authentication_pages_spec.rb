require 'spec_helper'

describe "Authentication" do
   
   subject { page }

   describe "signin" do
   	  before { visit signin_path }

   	  it { should have_selector('h1', text: 'PeregrineGuard') }
   	  it { should have_selector('h4', text: 'Agentless') }
   	  it { should have_selector('title', text: 'Sign in') }

      describe "with invalid information" do
   	     before { click_button "Login" }

   	     it { should have_selector('title', text: 'Sign in') }
   	     it { should have_selector('div.alert.alert-error', text: 'Invalid') }
      end

      describe "after visiting another page" do
      	 before { visit '/dash_inventory' }
      	 it { should_not have_selector('div.alert.alert-error') }
      end

      describe "with valid information" do

      	 describe "followed by signout" do
      	 	before { click_link "Logout" }
      	 	it { should have_link('Login') }
      	 end
      end
  end

end
