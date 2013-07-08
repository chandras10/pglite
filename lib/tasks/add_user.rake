namespace :db do
   desc "Create initial users"
   task addusers: :environment do
   	  admin = User.create(name: "admin",
   	  	          password: "peregrine",
   	  	          password_confirmation: "peregrine")
        admin.toggle!(:admin)
   
        user = User.create(name: "user",
                   password: "welcome12",
                   password_confirmation: "welcome12")

   end
end