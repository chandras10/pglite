class UsersController < ApplicationController
	before_filter :signed_in_user, only: [:index, :edit, :update, :show]
	before_filter :correct_user, only: [:edit, :update]
	before_filter :admin_user, only: :destroy

	def show
		@user = User.find(params[:id])
	end

    def create
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

    def index
    	@users = User.paginate(page: params[:page])
    end

    def destroy
    	user = User.find(params[:id]).destroy
    	flash[:success] = "User: #{user.name} destroyed."
    	redirect_to users_url
    end

	private
	   def correct_user
	   	   @user = User.find(params[:id])
	   	   redirect_to(root_path) unless current_user?(@user)
	   end

end
