require "luasql.mysql"
mysql = luasql.mysql()
local dbBase = "dbo_molinetes1"
local dbUser = "root"
local dbPass = "pirulo"
local dbHost = "172.31.1.1"

connMy, serr = mysql:connect(dbBase, dbUser, dbPass, dbHost)
