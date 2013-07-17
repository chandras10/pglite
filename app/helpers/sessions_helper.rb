require 'net/ldap'
module SessionsHelper

   def sign_in(user)
         # Save cookie, only if user says "Remember me" on the login screen. 
         # else, save it only for this session.
         if Rails.application.config.authentication == "ActiveDirectory"
               # Dont save cookies for AD authentication
               session[:remember_user] = user
         else
            if (params[:session] && params[:session][:remember_me])
               cookies.permanent[:remember_user] = user.remember_token
            else
               session[:remember_user] = user.remember_token
            end
         end

   	   self.current_user = user
   end

   def signed_in?
   	   !current_user.nil?
   end
   
   def signed_in_user
      unless signed_in?
         store_location
         redirect_to signin_url
      end
   end

   def sign_out
   	   self.current_user = nil
   	   cookies.delete(:remember_user)
   	   session.delete(:remember_user)
   end

   def current_user=(user)
   	   @current_user = user
   end

   def current_user
         if Rails.application.config.authentication == "ActiveDirectory"
            @current_user = session[:remember_user]
         else
   	      # Get the user based on remember_token, if and only if current_user is undefined
            token = session[:remember_user] || cookies[:remember_user] 
   	      @current_user ||= User.find_by_remember_token(token)
         end
   end

   def current_user?(user)
   	   user == current_user
   end

   def redirect_back_or(default)
   	   redirect_to(session[:return_to] || default)
   	   session.delete(:return_to)
   end

   def store_location
   	   session[:return_to] = request.url
   end

   def admin_user
       signed_in_user
       redirect_to(signin_path) unless current_user.admin?
   end
end
