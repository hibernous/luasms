socket = require("socket")
json = require("json")
require "luasql.mysql"
mysql = luasql.mysql()

--require("db.Class")
--local dbCon = dbClass.new("molinetes","root", "pirulo","mysql", "172.17.0.56")

local host = "172.17.0.56"
local connMy, serr = mysql:connect("molinetes","root", "pirulo", host)



function retData(strData)
	io.write("Contetnt-Type: text/xml; charset=UTF-8\r\n")
	io.write("Status: 200\r\n")
	io.write("\r\n")
	io.write(strData)
	io.write("\r\n")
end

function connectSocket(host, port)
	local cli
	cli, skerror = socket.connect(host, port)
	if not cli then 
		t = {}
		t.type = "Error"
		t.msg = skerror
		retData(json.encode(t))
		os.exit(0)
	end
	t = {}
	t.type = "setObject"
	t.object = "webclient"
	t.event = "entrasale"
	cli:send(json.encode(t).."\n")
	return cli
end

local host = "172.17.0.56"
local port = "8181"
local cli = connectSocket(host, port)

local lee = cli:receive()
local reg = json.decode(lee)
sql = string.format([[
SELECT 
oficinas.name AS OfName,
organismos.name AS OrgName
FROM `molinetes`.`ofi_mov` 
	left join (`molinetes`.`oficinas`,`molinetes`.`organismos`) 
	ON (oficinas.idoficina=ofi_mov.idoficina and organismos.idorganismo=oficinas.idorganismo) 
WHERE idpersona='%s' ORDER BY idofi_mov DESC limit 1
]], reg.persona);

--local cur, seer = dbCon:execute(sql)
--[[
if cur then
	local row = cur:fetch ({}, "a")
	if row then
		reg.OfName = row.OfName
		reg.OrgName = row.OrgName
	end
	cur:close()
end
dbCon:close()
]]
--reg.hora = os.date("%x %X",reg.time)

lee=json.encode(reg)
--cur:close()
retData(lee)
os.exit(0)
