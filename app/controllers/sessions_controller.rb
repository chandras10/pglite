class SessionsController < ApplicationController
   def new
   	   flash.now[:info] = "Please login with your Username and Password."
   end

   def create

      if Pglite.config.authentication == "ActiveDirectory"
         user = ActiveDirectoryUser.authenticate(params[:session][:name].downcase, params[:session][:password])
      else 
         user = User.find_by_name(params[:session][:name].downcase)
         if !(user && user.authenticate(params[:session][:password]))
            user = nil # didnt find the user or authentication failed!
         end
      end
      
   	if user 
   	  	sign_in user
   	  	redirect_back_or root_path
   	else
   	  	flash.now[:error] = 'Invalid name/password combination'
   	  	render 'new'
   	end
   end

   def destroy
   	  sign_out
   	  redirect_to signin_path
   end
end
