class CreateDeviceinfos < ActiveRecord::Migration
  def change
    create_table :deviceinfos do |t|
      t.string :macid
      t.string :username
      t.string :groupname
      t.string :location
      t.string :devicename
      t.string :classname
      t.string :osversion
      t.string :devicetype
      t.integer :weight
      t.string :ipaddr

      t.timestamps
    end
  end
end
