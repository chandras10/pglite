#
# Create two users, initially, in case the local database is used for authentication
# Records are added only if the database is fresh or the user table doesnt have any records
#
if User.all.empty? then
      admin = User.create(name: "admin",
   	  	          password: "peregrine",
   	  	          password_confirmation: "peregrine")
      admin.toggle!(:admin)
   
      user = User.create(name: "user",
                   password: "welcome12",
                   password_confirmation: "welcome12")
end
