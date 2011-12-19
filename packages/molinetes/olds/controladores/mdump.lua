--[[
	Este progama es para controlar 1 molinete de Macronet
	Los molinetes de Macronet son autónomos por tal motivo
	este programa actúa como cliente de los Molinetes enviando
	mensajes para :
		- controlar que estén en hora y/o ponerlos en hora
		- obtener fichadas y grabarlas en la base de datos MySQL y msSQL
		- informar estado y lecturas a un servidor de monitoreo y control todos los dispositivos
		- recibir ordenes especiales via socket desde el servidor de monitoreo y control
	Debe recibir como parametros
		los argumentos se pasan con en pares 
			ARGNAME=ARGVALUE
			y pueden ser los siguientes
			molip=ip_molinete				- obligatorio si no hay coneccion con db
			molserial=nro_serial_macronet	- obligatorio si no hay coneccion con db
			molid=nro_idctrl_en_db			- si solo se pasa este nro y hay conexion db 
												todos los valores se toman de la db sino 
												termina el programa.
			molmac=mac_address molinete		- opcional
			molprotocol=protocol (udp o tcp)- default udp
			molport=molinete_puerto			- default 3010
			
			srvip=server_ip
			srvport=srv_port
			
		arg[1] = IP del molinete
		arg[2] = MACADDRESS (opcional)
	al arrancar 
]]
require("ctrls_common")
require "luasql.odbc"
mssql = luasql.odbc()
DEBUG 	= 2
local params = {}
params.program=arg[0]
for k, v in pairs(arg) do
--	print(k,v)
	if k > 0 then
		_, _, name, value = string.find(v,"([^=]+)=(.+)")
		params[name]=value
	end
end
strF		= {}
strF["0"]	= "GET_REGISTRA"
strF["1"]	= "SET_HORA"
strF["A"]	= "CHK_HORA"
strF["B"]	= "CHK_FICHADAS"
strF["XB"]	= "GET_FICHADA"
strF["XK"]	= "DEL_FICHADA"
strF["XS"]	= "DET_FICHADA"

cmdsec = {"0","A","1","B","XB","XK","XS"}

local es	= {}
es["0"] 	= "Entra"
es["1"] 	= "Sale"
es["2"]		= "Buzon-Sale"
es["3"]		= "Desconocido"
es["4"]		= "No Entra"
es["5"]		= "No Sale"
es["6"]		= "Buzon-No Sale"


function openMy()
--	local host = "172.17.0.56"
	local host = "127.0.0.1"
	local connMy, serr = mysql:connect("molinetes","root", "pirulo", host)
	if not connMy then
--		printDL(2,"Error al conectar con MySql en Host: "..host)
		printDL(2,serr)
	end
	return connMy
end

function openMS(data)
	local dataSource = data
	local connMS, errText = mssql:connect(dataSource,"sa","vamosGlobant") 
	if not connMS then
		printDL(2,string.format("Error al conectar MS-SQL con ODBC DataSource '%s'",dataSource))
		printDL(2,errText)
--		os.exit(1)
	end
	return connMS
end

function webInfo(m)
	t = m
	t.event = "molinetestatus"
	for k,v in pairs(m.fail) do
		t[k] = v
	end
	t.type = "molinfo"
	params.srvskt:send(json.encode(t).."\n")
end

function showErrors(m)
	local str = string.format("id:%s host:%s port:%s Err: ", m.serie, m.host, m.port)
	for k,v in pairs(m.fail) do
		str = str .. string.format("%s:%d ",k,v)
	end
	printDL(5,"\n")
	printDL(5,str)
end

function get_moldata(sql)
	print("get_moldata")
	local t = {}
	local cur, dbErr = doSql(params.myDB,sql)
	if dbErr then 
		print(dbErr)
		os.exit(0) 
	end
	local row = cur:fetch ({}, "a")
	if row then
		local n = row.id
		row.Numero = tonumber(row.idctrls)
		t.name		= row.name
		t.mac		= row.mac
		if params.molip and params.molip ~= row.ip then
			print("IP no coinside con la almacenada en la base de datos")
			row.ip = params.molip
		end
		t.host		= row.ip
		t.type		= row.tipo
		t.numero	= row.Numero
		t.serie		= row.id
		t.port		= row.port or 3010
		t.protocol	= row.protocol
		t.timelastset = 0
--
--
		t.lastreg    = {}
--
--
		t.fail		= {}
		t.fail["0"]	= 0
		t.fail["1"]	= 0
		t.fail["A"]	= 0
		t.fail["B"]	= 0
		t.fail["XB"]	= 0
		t.fail["XK"]	= 0
		t.fail["XS"]	= 0
		t.fail["CM"]	= 0
		sql = string.format("SELECT CAST(Id AS VARCHAR(36)) AS uId FROM Molinetes WHERE Serie='%s'",t.serie)
		local cur, serr = doSql(params.msDB, sql)
		local row = cur:fetch ({}, "a")
		t.uId = row.uId
	end
	cur:close()
	return t
end
params.myDB = openMy()
	params.msDB, dbErr = openMS("moli")

if params.myDB then
	local sqlStr = ""
	if params.myDB and params.molid then
		sqlStr = string.format("SELECT * FROM `molinetes`.`ctrls` WHERE idctrl='%s'",params.molid)
	elseif params.myDB and params.molip ~= nil then
		sqlStr = string.format("SELECT * FROM `molinetes`.`ctrls` WHERE ip='%s'",params.molip)
	end
	params.device = get_moldata(sqlStr)
end

if params.srvip and params.srvport then
	params.srvskt, b = socket.connect(params.srvip, params.srvport)
	local tcontrol = {}
	tcontrol.type = "setObject"
	tcontrol.object = "controler"
	tcontrol.device = params.device
	params.srvskt:send(json.encode(tcontrol).."\n")
end
	
function doblesendmsgNoAnswer(m,s)
	local stx="" -- string.char(2)
	local etx="" -- string.char(3)
	local msg = stx..s..etx
	msg = msg..parityBit(msg)
	printDL(7,"Envia:", strF[m.f], msg)
	local bs, serr = m.cli:send(msg)
--	local bs, serr = m.cli:send(msg)
	if serr then
		printDL(1,string.format("Error %s \n\tal enviar comando '%s' a %s", serr, msg, m.name))
	end
	if bs == msg:len() then
		m.rspta = nil
		local c = 0
		while m.rspta == nil and c < 2 do
			m.rspta, m.serr = m.cli:receive()
			c = c+1
		end
		return m
	end
	return nil
end

function readMemory(m)
	local r = {}
	r.year = m.time.year
	r.wday = m.time.wday
	r.sec = m.time.sec
	r.status = false
	if m.serr == nil then
		local parity = m.rspta:sub(-1)
		local msg = m.rspta:sub(2,-3)
		r.msg = msg
--		print(m.rspta)
		print(msg)
		r.b = {}
		_, _, r.b[1], r.b[2], r.b[3], r.b[4], r.b[5], r.b[6], r.b[7], r.b[8], r.b[9], r.b[10], r.b[11], r.b[12], r.b[13], r.b[14], r.b[15], r.b[16]  = msg:find("(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)")
--[[
		for i=1, 16 do
			print(r.b[i])
		end
]]
	end
	return r
end

function doblesendmsg(m,s)
	local stx="" -- string.char(2)
	local etx="" -- string.char(3)
	local msg = stx..s..etx
	msg = msg..parityBit(msg)
	printDL(7,"Envia:", strF[m.f], msg)
	local bs, serr = m.cli:send(msg)
	local bs, serr = m.cli:send(msg)
	if serr then
		printDL(1,string.format("Error %s \n\tal enviar comando '%s' a %s", serr, msg, m.name))
	end
	if bs == msg:len() then
		m.rspta = nil
		local c = 0
		while m.rspta == nil and c < 2 do
			m.rspta, m.serr = m.cli:receive()
			c = c+1
		end
		if m.rspta == nil then
--			print("1-No acepto el mensaje "..msg)
			return nil
		elseif m.rspta == string.char(6) then 
			m.rspta, m.serr = m.cli:receive()
			if m.serr then 
--				print("No acepto el mensaje "..msg)
				return nil
			else
				return readMemory(m)
			end
		elseif m.rspta:sub(1,1) == string.char(6) then
			m.rspta = m.rspta:sub(2)
			return readMemory(m)
		else
--			print("2-No acepto el mensaje "..msg)
			return nil
		end
	end
	return nil
end

function getnum(s)
	return (string.gsub(s, "......", function (c)
			return string.upper(c)
			end)
			)
end

m = params.device
m.time = os.date("*t", socket.gettime())
m.time.wday = m.time.wday - 1
m.now = socket.gettime()

--while 1 do
a = tonumber(string.hex2dec("9500"))
u = tonumber(string.hex2dec("E880"))
print(a, b)
m.cli = socket.udp()
m.cli:settimeout(5,"t")
m.cli:setpeername(m.host, m.port)
t1 = socket.gettime()
local n = tonumber(a)
dump = ""
while n <= tonumber(u) do
	rpt = doblesendmsg(m,"S"..m.serie.."9"..string.dec2hex(n):upper())
	if rpt then 
		n = n + 16
		dump = dump..rpt.msg
	end
end
fm = io.open("dump.txt","w")
fm:write(dump)
fm:close()
m.cli:close()
m.cli = nil

print(socket.gettime()-t1)
n = 1
for  num in string.gmatch(dump,"........") do
--	nro = string.gsub(num,"..", function(c) return string.byte(c,16) end)
	print(n,num,sint32Tonum(num))
	n = n + 1
end

--[[
	m.cli = socket.udp()
	m.cli:settimeout(3,"t")
	m.cli:setpeername(m.host, m.port)
	m.f = params.cmd
	doblesendmsg(m,"S"..m.serie..params.cmd)
	m.cli:close()
	m.cli = nil
	printDL(5,"-------------------------------------------------")
]]
--end
