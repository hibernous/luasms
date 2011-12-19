require("ctrls_common")
require "luasql.mysql"
mysql = luasql.mysql()
local host = "127.0.0.1"
local connMy, serr = mysql:connect("molinetes","root", "pirulo", host)

fm = io.open("dump.txt")
dump = fm:read("*a")
--[[
dump = string.gsub(dump,"..", function(c)
		return string.char(string.char(tonumber(c, 16)))
		end)
]]
for num in string.gmatch(dump,"........") do
	num = string.hex2dec(num)
--	num = int32Tonum(num)
	print(num)
	local sql = string.format("SELECT * from `molinetes`.`tarjetas` WHERE idtarjeta='%s'", num)
	local cur, serr = connMy:execute(sql)
	if cur then
		local row = cur:fetch({},"a")
		if row then
			print(row.idtarjeta)
			io.read()
		end
	end
	if tostring(num) == tostring(arg[1]) then io.read() end
end

	local sql = string.format("SELECT * from `molinetes`.`tarjetas` WHERE idtarjeta='%s'", arg[1])
	local cur, serr = connMy:execute(sql)
	if cur then
		local row = cur:fetch({},"a")
		if row then
			print(row.idtarjeta)
			io.read()
		end
	end
test = numToint32(arg[1]) 
print(test)
print(string.dec2hex(arg[1]))
print(int32Tonum(test))
print(sint32Tonum(test))
