class UsersController < ApplicationController
	before_filter :signed_in_user, only: [:edit, :update]
	before_filter :correct_user, only: [:edit, :update]

	def show
		@user = User.find(params[:id])
	end

	def create
		# We dont have user sign ups yet in PG...
	end

	def edit
	end

	def update
		if @user.update_attributes(params[:user])
		   flash[:success] = "User profile updated"
		   sign_in @user
		   redirect_to @user
	    else
	       render 'edit'
	    end
	end

	private
	   def correct_user
	   	   @user = User.find(params[:id])
	   	   redirect_to(root_path) unless current_user?(@user)
	   end
end
