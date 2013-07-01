require 'spec_helper'

describe "users/show" do
  before(:each) do
    @user = assign(:user, stub_model(User,
      :name => "Name",
      :password_digest => "Password Digest",
      :remember_token => "Remember Token",
      :admin => false
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
    rendered.should match(/Password Digest/)
    rendered.should match(/Remember Token/)
    rendered.should match(/false/)
  end
end
