# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131111105752) do

  create_table "alertdb", :id => false, :force => true do |t|
    t.datetime "timestamp"
    t.integer  "eventid"
    t.string   "srcmac",    :limit => nil
    t.string   "dstmac",    :limit => nil
    t.integer  "protocol"
    t.string   "srcip",     :limit => nil
    t.integer  "srcport"
    t.string   "destip",    :limit => nil
    t.integer  "destport"
    t.integer  "sigid"
    t.integer  "sigrev"
    t.integer  "classid"
    t.integer  "priority"
    t.string   "message",   :limit => nil
  end

  create_table "appidexternal", :id => false, :force => true do |t|
    t.integer "appid",                  :null => false
    t.string  "appname", :limit => nil
  end

  create_table "appidinternal", :id => false, :force => true do |t|
    t.integer "appid",                  :null => false
    t.string  "appname", :limit => nil
  end

  create_table "appipexternal", :id => false, :force => true do |t|
    t.string  "iprange", :limit => nil,                :null => false
    t.integer "mask",                                  :null => false
    t.integer "appid"
    t.integer "port",                   :default => 0
  end

  create_table "appipinternal", :id => false, :force => true do |t|
    t.string  "iprange", :limit => nil,                :null => false
    t.integer "mask",                                  :null => false
    t.integer "appid"
    t.integer "port",                   :default => 0
  end

  create_table "application", :force => true do |t|
    t.string "vendor",   :limit => nil
    t.string "app_name", :limit => nil
    t.string "version",  :limit => nil
    t.string "revision", :limit => nil
    t.string "platform", :limit => nil
  end

  create_table "appregex", :id => false, :force => true do |t|
    t.integer "appid",                :null => false
    t.string  "regex", :limit => nil, :null => false
  end

  create_table "auth_devices", :id => false, :force => true do |t|
    t.string  "mac",    :limit => nil, :null => false
    t.integer "source"
  end

  create_table "auth_sources", :force => true do |t|
    t.string "description", :limit => nil
  end

  create_table "browserversion", :id => false, :force => true do |t|
    t.string "macid",       :limit => 30, :null => false
    t.string "browsername", :limit => 30, :null => false
    t.string "version",     :limit => 30, :null => false
  end

  create_table "classdb", :id => false, :force => true do |t|
    t.integer "classid"
    t.string  "classname",   :limit => nil
    t.string  "description", :limit => nil
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0, :null => false
    t.integer  "attempts",   :default => 0, :null => false
    t.text     "handler",                   :null => false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "deviceinfo", :id => false, :force => true do |t|
    t.string   "macid",           :limit => nil,                                                :null => false
    t.string   "username",        :limit => nil
    t.string   "groupname",       :limit => nil
    t.string   "location",        :limit => nil
    t.string   "devicetype",      :limit => nil
    t.string   "operatingsystem", :limit => nil
    t.string   "osversion",       :limit => nil
    t.string   "deviceclass",     :limit => nil
    t.integer  "weight"
    t.decimal  "dvi",                            :precision => 4, :scale => 3, :default => 0.0
    t.string   "ipaddr",          :limit => nil
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "auth_source"
    t.string   "devicename",      :limit => nil
    t.string   "vendorname",      :limit => nil
    t.string   "parentmacid",     :limit => nil
    t.decimal  "dti",                            :precision => 4, :scale => 3, :default => 0.0
  end

  create_table "deviceinfos", :force => true do |t|
    t.string   "macid"
    t.string   "username"
    t.string   "groupname"
    t.string   "location"
    t.string   "devicename"
    t.string   "classname"
    t.string   "osversion"
    t.string   "devicetype"
    t.integer  "weight"
    t.string   "ipaddr"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "dvi_vuln", :id => false, :force => true do |t|
    t.string "mac",     :limit => 30, :null => false
    t.string "vuln_id", :limit => 30, :null => false
  end

  create_table "easdata", :id => false, :force => true do |t|
    t.string   "deviceid",        :limit => nil
    t.string   "userid",          :limit => nil
    t.string   "userdisplayname", :limit => nil
    t.string   "deviceos",        :limit => nil
    t.string   "devicetype",      :limit => nil
    t.string   "deviceuseragent", :limit => nil
    t.string   "devicemodel",     :limit => nil
    t.datetime "firstsynctime"
    t.datetime "lastsyncattemp"
    t.datetime "lastsyncsuccess"
    t.string   "macid",           :limit => nil
  end

  create_table "easua", :id => false, :force => true do |t|
    t.string "useragent",   :limit => nil, :null => false
    t.string "devicetype",  :limit => nil
    t.string "devicemodel", :limit => nil
    t.string "version",     :limit => nil
  end

  create_table "externalipstat", :id => false, :force => true do |t|
    t.datetime "timestamp"
    t.string   "deviceid",  :limit => 30
    t.string   "destip",    :limit => nil
    t.integer  "destport"
    t.integer  "inbytes",   :limit => 8
    t.integer  "outbytes",  :limit => 8
    t.string   "cc",        :limit => 2,   :default => "--"
  end

  create_table "externalresourcestat", :id => false, :force => true do |t|
    t.datetime "timestamp"
    t.string   "deviceid",  :limit => 30
    t.integer  "appid"
    t.integer  "inbytes",   :limit => 8
    t.integer  "outbytes",  :limit => 8
  end

  create_table "hlurlcatid", :id => false, :force => true do |t|
    t.integer "id",                  :null => false
    t.string  "name", :limit => nil
  end

  create_table "hlurlcatstat", :id => false, :force => true do |t|
    t.datetime "timestamp"
    t.string   "deviceid",  :limit => 30
    t.integer  "id"
    t.integer  "inbytes",   :limit => 8
    t.integer  "outbytes",  :limit => 8
  end

  create_table "homenet", :id => false, :force => true do |t|
    t.string "net", :limit => nil
  end

  create_table "hostnames", :id => false, :force => true do |t|
    t.string  "ip_address", :limit => 100,                 :null => false
    t.integer "host_type",  :limit => 2
    t.string  "name",                      :default => "", :null => false
  end

  create_table "i7alert", :id => false, :force => true do |t|
    t.datetime "timestamp"
    t.integer  "id",                       :null => false
    t.string   "srcmac",    :limit => nil, :null => false
    t.string   "dstmac",    :limit => nil
    t.integer  "proto"
    t.string   "srcip",     :limit => nil
    t.string   "dstip",     :limit => nil
    t.integer  "srcport"
    t.integer  "dstport"
    t.string   "pcap",      :limit => nil
    t.string   "message",   :limit => nil, :null => false
  end

  create_table "i7alertclassdef", :id => false, :force => true do |t|
    t.integer "id",                         :null => false
    t.string  "description", :limit => nil
  end

  create_table "i7alertdef", :id => false, :force => true do |t|
    t.integer "id",                                           :null => false
    t.integer "priority"
    t.integer "classid"
    t.string  "description", :limit => nil
    t.boolean "active",                     :default => true
  end

  create_table "i7internalalert", :id => false, :force => true do |t|
    t.datetime "timestamp"
    t.integer  "id",                       :null => false
    t.string   "srcmac",    :limit => nil, :null => false
    t.string   "dstmac",    :limit => nil
    t.integer  "proto"
    t.string   "srcip",     :limit => nil
    t.string   "dstip",     :limit => nil
    t.integer  "srcport"
    t.integer  "dstport"
    t.string   "pcap",      :limit => nil
    t.string   "message",   :limit => nil, :null => false
  end

  create_table "internalipstat", :id => false, :force => true do |t|
    t.datetime "timestamp"
    t.string   "deviceid",  :limit => 30
    t.string   "destip",    :limit => nil
    t.integer  "destport"
    t.integer  "inbytes",   :limit => 8
    t.integer  "outbytes",  :limit => 8
  end

  create_table "internalresourcestat", :id => false, :force => true do |t|
    t.datetime "timestamp"
    t.string   "deviceid",  :limit => 30
    t.integer  "appid"
    t.integer  "inbytes",   :limit => 8
    t.integer  "outbytes",  :limit => 8
  end

  create_table "intincomingipstat", :id => false, :force => true do |t|
    t.datetime "timestamp"
    t.string   "deviceid",  :limit => 30
    t.string   "destip",    :limit => nil
    t.integer  "destport"
    t.integer  "inbytes",   :limit => 8
    t.integer  "outbytes",  :limit => 8
  end

  create_table "ipstat", :id => false, :force => true do |t|
    t.datetime "timestamp"
    t.string   "deviceid",  :limit => 30
    t.string   "destip",    :limit => nil
    t.integer  "destport"
    t.integer  "inbytes"
    t.integer  "outbytes"
  end

  create_table "licenseinfo", :id => false, :force => true do |t|
    t.datetime "lastupdatetime"
    t.datetime "valid_until"
  end

  create_table "portmap", :id => false, :force => true do |t|
    t.integer "port",                     :null => false
    t.string  "shortname", :limit => nil
    t.string  "longname",  :limit => nil
  end

  create_table "product", :force => true do |t|
    t.string "vendor",     :limit => nil
    t.string "os_name",    :limit => nil
    t.string "os_version", :limit => nil
    t.string "revision",   :limit => nil
    t.string "arch",       :limit => nil
  end

  create_table "urlcatid", :id => false, :force => true do |t|
    t.integer "id",                  :null => false
    t.string  "name", :limit => nil
  end

  create_table "urlcatstat", :id => false, :force => true do |t|
    t.datetime "timestamp"
    t.string   "deviceid",  :limit => 30
    t.integer  "id"
    t.integer  "inbytes",   :limit => 8
    t.integer  "outbytes",  :limit => 8
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "password_digest"
    t.string   "remember_token"
    t.boolean  "admin",           :default => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "users", ["name"], :name => "index_users_on_name", :unique => true
  add_index "users", ["remember_token"], :name => "index_users_on_remember_token"

  create_table "version", :id => false, :force => true do |t|
    t.string   "version",     :limit => nil
    t.datetime "create_time"
  end

  create_table "vuln_app", :id => false, :force => true do |t|
    t.string  "vuln_id", :limit => nil
    t.integer "app_id"
    t.integer "prod_id"
  end

  create_table "vuln_product", :id => false, :force => true do |t|
    t.string  "vuln_id",    :limit => nil, :null => false
    t.integer "product_id",                :null => false
  end

  create_table "vulnerability", :id => false, :force => true do |t|
    t.string   "id",                       :limit => nil,                               :null => false
    t.datetime "publication_date"
    t.datetime "last_modify_date"
    t.string   "source",                   :limit => nil
    t.string   "summary",                  :limit => nil
    t.decimal  "cvss_score",                              :precision => 4, :scale => 2
    t.string   "cvss_access_vector",       :limit => nil
    t.string   "cvss_access_complexity",   :limit => nil
    t.string   "cvss_authentication",      :limit => nil
    t.string   "cvss_conf_impact",         :limit => nil
    t.string   "cvss_integrity_impact",    :limit => nil
    t.string   "cvss_availability_impact", :limit => nil
    t.string   "cvss_source",              :limit => nil
    t.datetime "cvss_gen_date"
  end

end
