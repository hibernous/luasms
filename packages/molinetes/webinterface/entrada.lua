socket = require("socket")
require "luasql.odbc"
mssql = luasql.odbc()
require "luasql.mysql"
mysql = luasql.mysql()
connMy, serr = mysql:connect("dbo_molinetes","root", "pirulo","localhost")

function openMS()
--	local connMS = mssql:connect("moli1","sa","vamosGlobant") 
	local connMS = mssql:connect("moli","fabian","pirulo") 
	if not connMS then
		print(serr)
		os.exit(1)
	end
	return connMS
end

--local connMS = openMS()
local cur, serror = connMy:execute("SELECT Ciudadanos_Id, Apellido, Nombre, Foto FROM Ciudadanos Limit 1000, 10000")
if serror then
	print(serror)
	os.exit(0)
end
io.write("Content-Type: text/html\r\n")
io.write("Status: 200\r\n\r\n")
local row = cur:fetch ({}, "a")
while row do
	print(row.Id,row.Apellido, row.Nombre,"<BR/>")
	print("<img src='foto.lua?foto="..row.Ciudadanos_Id.."'/><BR>")
--	socket.sleep(.5)
	row = cur:fetch ({}, "a")
end

