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
         let(:user) { FactoryGirl.create(:user)}
         before { sign_in user }

         it { should have_selector('title', text: 'PeregrineGuard') }
         it { should have_link('Profile', href: user_path(user)) }
         it { should have_link('Change Password', href: edit_user_path(user)) }
         it { should have_link('Logout', href: signout_path) }
         it { should_not have_link('Login', href: signin_path) }
      	 describe "followed by signout" do
      	 	before { click_link "Logout" }
      	 	it { should have_button('Login') }
      	 end
      end
  end

  describe "authorization" do
     let(:user) { FactoryGirl.create(:user)}

     describe "in the Users controller" do
        describe "visiting the edit page" do
           before { visit edit_user_path(user)}
           it { should have_selector('title', text: 'Sign in')}
        end

        describe "submitting to the update action" do
           before { put user_path(user) }
           specify { response.should redirect_to(signin_path) }
        end

        describe "visiting the user index" do
           before { visit users_path }
           it { should have_selector('title', text: 'Sign in') }
        end
     end

     describe "as wrong user" do
        let(:user) { FactoryGirl.create(:user)}
        let(:wrong_user) { FactoryGirl.create(:user, name: "wrong") }
        before { sign_in user }

        describe "visiting Users#edit page" do
           before { visit edit_user_path(wrong_user) }
           it { should_not have_selector('title', text: full_title('Edit user')) }
        end

        describe "submitting a PUT request to the Users#update action" do
           before { put user_path(wrong_user) }
           specify { response.should redirect_to(root_path)}
        end
     end

     describe "for non-signed-in users" do
        let(:user) { FactoryGirl.create(:user) }

        describe "when attempting to visit a protected page" do
           before do
              visit edit_user_path(user)
              fill_in "username", with: user.name
              fill_in "password", with: user.password
              click_button "Login"
           end

           describe "after signing" do
              it "should render the desired protected page" do
                 page.should have_selector('title', text: 'Edit user')
              end
           end
        end
     end

     describe "as non-admin user" do
        let(:user) { FactoryGirl.create(:user) }
        let(:non_admin) { FactoryGirl.create(:user) }

        before { sign_in non_admin }

        describe "submitting a DELETE request to the User#destroy action" do
           before { delete user_path(user) }
           specify { response.should redirect_to(root_path) }
        end
     end
  end

end
