require 'spec_helper'

describe "User Pages" do

  subject { page }

  describe "profile page" do
    let(:user) { FactoryGirl.create(:user) }
    before { visit user_path(user) }

    it { should have_selector('h1',    text: user.name) }
    it { should have_selector('title', text: user.name) }
  end

  describe "edit" do
  	 let(:user) { FactoryGirl.create(:user) }
     before { visit edit_user_path(user) }

     describe "page" do
     	it { should have_selector('h2', text: "Update your profile") }
     	it { should have_selector('title', text: "Edit user") }
     end

     describe "with invalid information" do
     	before { click_button "Save changes" }

     	it { should have_content('error')}
     end

     describe "with valid information" do
     	let(:new_name) { "New Name"}
     	before do
     	   fill_in "Name", 			with: new_name
     	   fill_in "Password",		with: user.password
           fill_in "Confirm Password", with: user.password
           click_button "Save changes"
     	end

     	it { should have_selector('title', text: new_name)}
     	it { should have_selector('div.alert.alert-success')}
     	it { should have_link('Logout', href: signout_path)}
     	specify { user.reload.name.should == new_name }
     end
  end
end
