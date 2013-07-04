require 'spec_helper'

describe User do
   before { @user = User.new(name: "testuser", password: "foobar", password_confirmation: "foobar") }

   subject { @user }

   it { should respond_to(:name) }
   it { should respond_to(:password_digest) }
   it { should respond_to(:password) }
   it { should respond_to(:password_confirmation) }
   it { should respond_to(:authenticate) }
   it { should respond_to(:admin) }
   it { should respond_to(:remember_token) }

   it { should be_valid }
   it { should_not be_admin }

   describe "when name is not present" do
   	  before { @user.name = "" }
   	  it { should_not be_valid }
   end

   describe "when name is too long" do
   	  before { @user.name = "a" * 51 }
   	  it { should_not be_valid }
   end

   describe "when name is already taken" do
   	  before do
   	  	 user_with_same_name = @user.dup
   	  	 user_with_same_name.save
   	  end

   	  it { should_not be_valid }
   end

   describe "when password is not present" do
   	  before { @user.password = @user.password_confirmation = "" }
   	  it { should_not be_valid }
   end

   describe "return value of authenticate method" do
   	  before { @user.save }
   	  let(:found_user) { User.find_by_name(@user.name) }

   	  describe "with valid password" do
   	  	 it { should == found_user.authenticate(@user.password) }
   	  end

   	  describe "with invalid password" do
   	  	 let(:user_for_invalid_password) { found_user.authenticate("invalid") }

   	  	 it { should_not == user_for_invalid_password }
   	  	 specify { user_for_invalid_password.should be_false }
   	  end

   	  describe "with a password that's too short" do
   	  	 before { @user.password = @user.password_confirmation = "a" * 5 }
   	  	 it { should be_invalid }
   	  end
   end

   describe "remember token" do
   	  before { @user.save }
   	  its(:remember_token) { should_not be_blank }
   end

   describe "with admin attribute set to 'true'" do
      before do
         @user.save!
         @user.toggle!(:admin)
      end

      it { should be_admin }
   end
end
