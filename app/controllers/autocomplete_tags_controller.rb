class AutocompleteTagsController < ApplicationController

	def usernames
       if current_user && Rails.application.config.authentication == "ActiveDirectory"
          users = current_user.listUsers
       end
	   
	   userList = []
	   if !users.nil? then
          users.each do |u|
          	# Only return user names matching the partial string
             if (!params[:uname].nil? and u[:name].downcase.include? params[:uname].downcase)
                userList << u[:name]
             end
          end
       end
       render json: userList
	end

	def groupnames
       if current_user && Rails.application.config.authentication == "ActiveDirectory"
          users = current_user.listUsers
       end
	   
	   groups = []
	   if !users.nil? then
          users.each do |u|
          	 if !u[:groups].empty?
                groups << u[:groups]
             end
          end
       end

       groupList = groups.flatten.uniq {|g| g}.sort

       render json: groupList
	end
end