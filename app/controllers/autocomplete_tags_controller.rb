class AutocompleteTagsController < ApplicationController

	def usernames
       if current_user && Pglite.config.authentication == "ActiveDirectory"
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
       if current_user && Pglite.config.authentication == "ActiveDirectory"
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

  def countrycodes
   countryCodes = IsoCountryCodes.for_select
   countryList = []
   countryCodes.each do |c|
     if (!params[:countrycode].nil? and c[0].downcase.start_with? params[:countrycode].downcase)
       countryList << "#{c[1]} - #{c[0]}"
     end
   end
   render json: countryList.sort
  end

end
