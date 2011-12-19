--[[
	Este progama es para controlar 1 molinete de Macronet
	Los molinetes de Macronet son aut�nomos por tal motivo
	este programa act�a como cliente de los Molinetes enviando
	mensajes para :
		- controlar que est�n en hora y/o ponerlos en hora
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
DEBUG 	= 7
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


function checkHora(m)
	m.time = os.date("*t", socket.gettime())
	m.time.wday = m.time.wday - 1
	m.rspta, m.serr = m.cli:receive()
	m.f = "A"
	local t = doblesendmsg(m, "S"..m.serie.."A")
	if t then
		if t.status then
			if not (t.hour == m.time.hour
			and t.min == m.time.min
			and t.month == m.time.month
			and t.day == m.time.day) 
			then
				m.timelastdev = 0
				t.hour = m.time.hour
				t.min = m.time.min
				t.month = m.time.month
				t.day = m.time.day
--				setdate(m)
			else 
				m.timelastdev = socket.gettime()
			end
		end
	end
end
	
--[[
	Empieza el programa
]]

function makeNewData(m)
	local searchTrj = string.format([[SELECT * FROM `molinetes`.`trj_mov` where tarjeta='%s' ORDER By idtrj_mov DESC LIMIT 1]],m.read.trj)
	local cur, serr = doSql(params.myDB,searchTrj)
	if cur then
		local row = cur:fetch ({}, "a")
		if row then
			if row.tipo == "ASIGNA" then
				m.read.asignada=row.fecha
				m.read.persona=row.a
				m.read.event = "entrasale"
				cur:close()
				local searchPrs = string.format([[SELECT * FROM `molinetes`.`personas` WHERE id='%s']],m.read.persona)
				print(searchPrs)
				local cur, serr = doSql(params.myDB,searchPrs)
				if cur then
					local row = cur:fetch ({}, "a")
					m.read.name = tostring(row.apellidos).." "..tostring(row.nombres)
					m.read.valid = true
					m.read.type = "pasa"
					m.read.progId = arg[0]
					m.read.secTime = socket.gettime()
					cur:close()
				
				end
			end
		else
			printDL(2,"Numero de tarjeta Invalidad Molinete "..m.serie.." - "..m.name)
		end
	end
--	params.srvskt:send(json.encode(m.read).."\n")
end

function makeOldData (m)
	local sql = string.format(
[[
SELECT CAST(A.Tarjeta AS VARCHAR(36)) AS Tarjeta, CAST(A.Ciudadano AS VARCHAR(36)) AS Ciudadano, Ciudadanos.Apellido, Ciudadanos.Nombre FROM 
(
	select personal.Ciudadano, personal.Tarjeta from personal 
		left join ciudadanos ON ciudadanos.Id = personal.Ciudadano 
		where personal.Tarjeta=(SELECT Id FROM Tarjetas WHERE Numero='%s')
	union
	select Personal.Ciudadano, TarjetasTemporales.Tarjeta
	FROM TarjetasTemporales 
	LEFT JOIN Personal ON 
		Personal.Id = TarjetasTemporales.Personal
	WHERE TarjetasTemporales.Tarjeta = (SELECT Id FROM Tarjetas WHERE Numero='%s')
	AND TarjetasTemporales.Baja is null
	AND TarjetasTemporales.Alta = (
			  select Max(TarjetasTemporales.Alta)
			  from TarjetasTemporales 
			  where TarjetasTemporales.Tarjeta = (SELECT Id FROM Tarjetas WHERE Numero='%s')
			  AND TarjetasTemporales.Alta <= CONVERT(datetime,'%s', 102)
			)
	union 
	select Visitantes.Ciudadano, Visitantes_Tarjetas.Tarjeta 
	FROM Visitantes_Tarjetas 
	LEFT JOIN Visitantes ON 
		Visitantes.Id = Visitantes_Tarjetas.Visitante
	WHERE Visitantes_Tarjetas.Tarjeta = (SELECT Id FROM Tarjetas WHERE Numero='%s')
	AND Visitantes_Tarjetas.Alta <= CONVERT(datetime,'%s', 102)
	AND Visitantes_Tarjetas.Baja is null
) AS A LEFT JOIN Ciudadanos ON A.Ciudadano = Ciudadanos.Id
]], m.read.trj, m.read.trj, m.read.trj, m.read.strFecha, m.read.trj, m.read.strFecha)
	local cur, serr = doSql(params.msDB,sql)
	if cur then 
		local row, serr = cur:fetch({},"a")
		cur:close()
		if row then
			m.read.oldTrjId = row.Tarjeta
			m.read.oldCiuId = row.Ciudadano
			cur:close()
			sql = string.format([[INSERT INTO Fichadas VALUES
	(
		NEWID(),
		CAST('%s' AS UNIQUEIDENTIFIER),
		CAST('%s' AS UNIQUEIDENTIFIER),
		CONVERT(DATETIME, '%s',120),
		CAST('%s' AS UNIQUEIDENTIFIER),
		%s
	)
]], m.read.oldCiuId, m.read.oldTrjId, m.read.strFecha, m.uId, m.read.sensor)
			local rslt, serr = doSql(params.msDB, sql)
			if rslt == nil then 
				local strReg = string.format("%s;%s;%s;%s;%s\n",m.read.oldCiuId, m.read.oldTrjId, m.read.strFecha, m.uId, m.read.sensor)
				local oldReg, errtext, errcode = io.open("C:\\luatest\\oldregistros.dat","a")
				if oldReg == nil then
					printDL(1, string.format("oldregistros.dat '%s'", errtext))
				else
					local ok, errtext, errcode = oldReg:write(strReg)
					oldReg:close()
					if ok == true then
						printDL(4, string.format("oldregistros.dat:'%s;%s;%s;%s;%s'",m.read.oldCiuId, m.read.oldTrjId, m.read.strFecha, m.uId, m.read.sensor))
					else
						printDL(2, string.format("oldregistros.dat: '%s'", errtext))
					end
				end
			end
			if tonumber(m.read.sensor ) == 2 then
				sql = string.format([[
UPDATE Visitantes_Tarjetas SET Baja = CONVERT(DATETIME, '%s',120) WHERE Visitante IN 
	(SELECT Id FROM Visitantes WHERE Ciudadano = CAST('%s' AS UNIQUEIDENTIFIER))
	AND Baja is null
]], m.read.strFecha, m.read.oldCiuId)
				local rslt, serr = doSql(params.msDB, sql)
				if rslt == nil then
					local strReg = string.format("%s;%s\n", m.read.strFecha, m.read.oldCiuId)
					local oldReg, errtext, errcode = io.open("C:\\luatest\\oldvisitas.dat","a")
					if oldReg == nil then
						printDL(1, string.format("oldvisitas.dat '%s'", errtext))
					else
						local ok, errtext, errcode = oldReg:write(strReg)
						oldReg:close()
						if ok == true then
							printDL(4, string.format("oldvisitas.dat:'%s;%s'", m.read.strFecha, m.read.oldCiuId))
						else
							printDL(2, string.format("oldvisitas.dat: '%s'", errtext))
						end
					end
				end
			end
		end
	else
		local strReg = string.format("%s;%s;%s;%s\n", tostring(m.read.strFecha), tostring(m.read.Trj), tostring(m.serie), tostring(m.read.sensor))
		local oldReg, errtext, errcode = io.open("C:\\luatest\\oldfichadas.dat","a")
		if oldReg == nil then
			printDL(1, string.format("oldfichadas.dat '%s'", errtext))
		else
			local ok, errtext, errcode = oldReg:write(strReg)
			oldReg:close()
			if ok == true then
				printDL(4, string.format("oldfichadas.dat:'%s;%s;%s;%s'",tostring(m.read.strFecha), tostring(m.read.Trj), tostring(m.serie), tostring(m.read.sensor)))
			else
				printDL(2, string.format("oldfichadas.dat: '%s'", errtext))
			end
		end
	end
end

function saveData(m)
	m.read.strFecha = string.format("%d-%02d-%02d %02d:%02d:%02d", m.read.year, m.read.month, m.read.day, m.read.hour, m.read.min, 0)
	m.read.time = os.time({year = m.read.year, month = m.read.month, day = m.read.day, hour = m.read.hour, min = m.read.min, sec = 0})
	m.read.lectorname = es[m.read.sensor]
	m.read.molineteId = m.name
	makeNewData(m)
	local sql = string.format([[SELECT * FROM registros WHERE fecha='%s' AND controler='%s' AND tpmov='%s' AND tarjeta='%s']], m.read.strFecha, m.serie, m.read.sensor, m.read.trj)
	local cur, serr = doSql(params.myDB, sql)
	if cur then
		if cur:numrows() == 0 then
			if m.read.persona == nil then
				m.read.persona = "NULL"
			else
				m.read.persona = "'"..m.read.persona.."'"
			end
			local sql = string.format(
[[INSERT INTO registros (fecha, operator, controler, tpmov, tarjeta, persona) 
	VALUES ('%s', '%s', '%s', '%s', '%s', %s)
]], m.read.strFecha, 0, m.serie, m.read.sensor, m.read.trj, (m.read.persona or "NULL"))
			local rslt, serr = doSql(params.myDB, sql)
			if rslt then
				if m.read.sensor == 2 then
					local sql = string.format([[
INSERT INTO trj_mov (fecha, tarjeta, tipo, de, a) 
	VALUES ('%s', '%s', '%s', '%s', '%s')
]], m.read.strFecha, m.read.trj, "BUZON", (m.read.persona or "NULL"), m.serie)
					local rslt, serr = doSql(params.myDB, sql)
					if serr then 
						printDL(2,"%s ('%s', '%s', '%s', '%s', '%s')", serr, m.read.strFecha, m.read.trj, "BUZON", (m.read.persona or "NULL"), m.serie)
					end
				end
				makeOldData(m)
				return true
			else
				return false
			end
		else
			return true
		end
		cur:close()
	else
		return false
	end
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

function checkCommands(m)
	local strSQL = string.format([[SELECT CAST(Id AS VARCHAR(36)) AS Id, Comando
		FROM ComandosDiferidos
		WHERE (Molinete = '%s')]], m.uId)
	local cur, serr = doSql(params.msDB, strSQL)
	local row = cur:fetch ({}, "a")
	local tcommands = {}
	while row do
		tcommands[#tcommands+1] = {cmdId=row.Id, cmdstr=row.Comando}
--		print(tcommands[#tcommands].cmdId, tcommands[#tcommands].cmdstr, row.Co)
		row = cur:fetch ({}, "a")
	end
	cur:close()
	if #tcommands > 0 then
		for i, t in ipairs(tcommands) do
			local mymsg = sendcmd(m, t.cmdstr)
			m.rspta, m.serr = m.cli:receive()
			m.f = "CM"
			if m.rspta == string.char(6) then
				strSQL = string.format("DELETE FROM ComandosDiferidos WHERE Id='%s'", t.cmdId)
				local rslt, serr = doSql(params.msDB, strSQL)
				m.fail[m.f] = 0
			else
				m.fail[m.f] = m.fail[m.f] + 1
				local strerr = "Error al enviar comando "..t.cmdstr
				printDL(errorLevel(m,strerr))
				break
			end
	end
	end
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
		print(m.rspta)
		print(msg)
		r.b = {}
		_, _, r.b[1], r.b[2], r.b[3], r.b[4], r.b[5], r.b[6], r.b[7], r.b[8], r.b[9], r.b[10], r.b[11], r.b[12], r.b[13], r.b[14], r.b[15], r.b[16]  = msg:find("(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)")
		for i=1, 16 do
			print(r.b[i])
		end
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
			print("1-No acepto el mensaje "..msg)
		elseif m.rspta == string.char(6) then 
			m.rspta, m.serr = m.cli:receive()
			if m.serr then 
--				print("No acepto el mensaje "..msg)
			else
				return readMemory(m)
			end
		elseif m.rspta:sub(1,1) == string.char(6) then
			m.rspta = m.rspta:sub(2)
			return readMemory(m)
		else
			print("2-No acepto el mensaje "..msg)
		end
	end
	return nil
end

function sendmsg(m,s)
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
	print(bs, serr)
	if bs == msg:len() then
		m.rspta, m.serr = m.cli:receive()
		if m.serr then 
			m.rspta, m.serr = m.cli:receive()
		end
		if m.serr then 
			print("No acepto el mensaje "..msg)
		else
			print(m.rspta, m.serr)
			return decodeMsg(m)
		end
	end
	return nil
end

function sendcmd(m,s)
	printDL(7,"Envia:", s)
	local bs, serr = m.cli:send(s)
	if serr then
		printDL(1,string.format("Error %s \n\tal enviar comando '%s' a %s", serr, s, m.name))
	end
	return bs
end

function decodeMsg(m)
	local r = {}
	r.year = m.time.year
	r.wday = m.time.wday
	r.sec = m.time.sec
	r.status = false

	if m.serr == nil then
--		printDL(5,string.format("%s decodeMsg '%s' id:%s-%s", strF[m.f], m.rspta,m.serie, m.name))
		m.timeout = 0
--		m.cli:send(string.char(6))
		local parity = m.rspta:sub(-1)
		local msg = m.rspta:sub(2,-3)
		print(m.rspta)
		print(msg)
--		if parityBit(msg) == parity then
			_, _, r.code, r.sensor = msg:find("(.)(.)%x%x%x%x%x%x%x%x")
			if r.code == "A" then
				_, _, r.code, r.sensor, r.month, r.day, r.hour, r.min, r.molId = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d)")
--				print(r.code, r.sensor, r.month, r.day, r.hour, r.min, r.molId)
				if r.code
				and r.sensor
				and r.month
				and r.day
				and r.hour
				and r.min
				and r.molId
				then
					m.fail[m.f] = 0
					r.status = true
					local strerr = string.format("%s: %04d-%02d-%02d %02d:%02d:%02d %s-%s", strF[m.f], r.year, r.month, r.day, r.hour, r.min, r.sec, m.serie, m.name)
					printDL(5,strerr)
--[[
				else
					_, _, r.code, r.sensor, r.fecha, r.hora, r.secuencia,r.molId = msg:find("(.)(.)(..).(..).(%d%d)(%d%d%d%d%d)")
					if r.code
					and r.sensor
					and r.fecha
					and r.hora
					and r.secuencia
					and r.molId
					then
						local strerr = string.format("%s: %04d-%02d-%02d %02d:%02d:%02d %s-%s", strF[m.f], r.year, r.month, r.day, r.hour, r.min, r.sec, m.serie, m.name)
						m.fail[m.f] = 0
						r.status = true
						r.month = m.time.month
						r.day = m.time.day
						r.hour = m.time.hour
						r.min = m.time.min
						printDL(5,r.code, r.sensor, r.fecha, r.hora, r.secuencia,r.molId)
						printDL(5,r.code, r.sensor, r.month, r.day, r.hour, r.min, r.lolId)
					end
]]
				end
			elseif r.code == "B" then
				_, _, r.code, r.sensor, r.month, r.day, r.hour, r.min, r.cnt = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d)")
--				print(r.code, r.sensor, r.month, r.day, r.hour, r.min, r.cnt)
				if r.code
				and r.sensor
				and r.month
				and r.day
				and r.hour
				and r.min
				and r.cnt
				then
					local strerr = string.format("%s(%s): %04d-%02d-%02d %02d:%02d:%02d (%s)", strF[m.f], r.sensor, r.year, r.month, r.day, r.hour, r.min, r.sec, r.cnt)
					m.fail[m.f] = 0
					r.status = true
					r.cnt = tonumber(r.cnt)
					printDL(5,strerr)
--					printDL(5,r.code, r.sensor, r.month, r.day, r.hour, r.min, tonumber(r.cnt))
				end
			elseif r.code == "0" then -- Respuesta Acceso a Memoria
				r.b = {}
				_, _, r.b[1], r.b[2], r.b[3], r.b[4], r.b[5], r.b[6], r.b[7], r.b[8], r.b[9], r.b[10], r.b[11], r.b[12], r.b[13], r.b[14], r.b[15], r.b[16]  = msg:find("(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)(%x%x)")
				for i=1, 16 do
					print(r.b[i])
				end
			elseif r.code == "2" then
				_, _, r.code, r.sensor, r.month, r.day, r.hour, r.min, r.trj, r.molId, r.secuencia = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d%d%d%d%d%d)(%d%d%d%d%d)(%d%d)")
--				print(r.code, r.sensor, r.month, r.day, r.hour, r.min, r.trj, r.molId, r.secuencia)
				if r.code
				and r.sensor
				and r.month
				and r.day
				and r.hour
				and r.min
				and r.trj
				and r.molId
				and r.secuencia
				then
					m.fail[m.f] = 0
					r.status = true
					r.secuencia = tonumber(r.secuencia)
					r.trj = tonumber(r.trj)
					local strerr = string.format("%s: %04d-%02d-%02d %02d:%02d:%02d trj:%10s sec:%2s m:%s %s", strF[m.f], r.year, r.month, r.day, r.hour, r.min, 0, r.trj, r.secuencia, r.molId, es[r.sensor])
					printDL(5,strerr)
				else
					_, _, r.code, r.sensor, r.month, r.day, r.hour, r.min, r.trj = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d%d%d%d%d%d)")
					if r.code
					and r.sensor
					and r.month
					and r.day
					and r.hour
					and r.min
					and r.trj
					then
						local strerr = string.format("%s: BAD DATE FORMAT %s:%s", strF[m.f], m.serie, m.name)
						m.fail[m.f] = 0
						r.status = true
						r.trj = tonumber(r.trj)
						printDL(5, strerr)
						printDL(5,r.code, r.sensor, r.month, r.day, r.hour, r.min, r.trj)
					end
				end
			else
				if m.fail[m.f] == nil then m.fail[m.f] = 0 end
				print("R.CODE",r.code)
				m.fail[m.f] = m.fail[m.f] + 1
				local strerr = string.format("%s: Rspta No Procesada:'%s' (%d) id:%s-%s", (strF[m.f] or m.f), addslashes((m.rspta or "")), m.fail[m.f], m.serie, m.name)
				printDL(errorLevel(m,strerr))
			end
--[[
		else
			m.fail[m.f] = m.fail[m.f] + 1
			local strerr = string.format("%s: Invalid response:'%s' count(%d) id:%s-%s", strF[m.f], addslashes(m.rspta), m.fail[m.f], m.serie, m.name)
			printDL(errorLevel(m,strerr))
		end
]]
	else
		m.fail[m.f] = m.fail[m.f] + 1
		local strerr = string.format("%s: Socket:%s count(%d) %s-%s", strF[m.f], m.serr, m.fail[m.f], m.serie, m.name)
		printDL(errorLevel(m,strerr))
	end
	if r.month then r.month = tonumber(r.month) end
	if r.day then r.day = tonumber(r.day) end
	if r.hour then r.hour = tonumber(r.hour) end
	if r.min then r.min = tonumber(r.min) end
	m.read = r
	return r
end

function checkFichadas(m)
	m.f = "B"
	local mymsg = doblesendmsg(m,"S"..m.serie..m.f)
--	m.rspta, m.serr = m.cli:receive()
--	t = decodeMsg(m)
--[[
	if t.status and t.cnt then
		if t.cnt > 0 then
			getRegistracioes(m)
		end
	else
		print("CheckFichas",t.status )
	end
]]
end

function getRegistracioes(m)
	m.f = "XB"
	local t = doblesendmsg(m,"S"..m.serie..m.f)
	if t then
--	if m.serr == nil then 
----		t = decodeMsg(m)
--		if t.status and t.secuencia then
--			local fecha = string.format("%d-%02d-%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, 0)
--		end
--		if t.secuencia and t.status then
		while t and t.secuencia and t.status do
			if saveData(m,t) == true then
				m.paso = true
				m.f = "XK"
				local mymsg = doblesendmsg(m,string.format("S%05dXK%02d",m.serie,t.secuencia))
				m.f = "XB"
				t = doblesendmsg(m,"S"..m.serie..m.f)
			else
				t.status = nil
				t.secuencia = nil
			end
		end
--	end
	end
end

function setdate(m)
	if socket.gettime() - m.timelastset > 60 then
		m.f = "1"
		local mymsg = doblesendmsgNoAnswer(m, string.format("S%s1%02d%02d%02d%d%02d%02d%02d",m.serie,string.sub(m.time.year,-2), m.time.month, m.time.day, m.time.wday, m.time.hour, m.time.min, m.time.sec))
		if m.serr then
			m.fail[m.f] = m.fail[m.f] + 1
			printDL(errorLevel(m,string.format("%s: Socket:%s count(%d) %s-%s",strF[m.f], m.serr, m.fail[m.f], m.serie, m.name)))
		else
			m.timelastset = socket.gettime()
			printDL(errorLevel(m,string.format("%s OK: %04d-%02d-%02d %02d:%02d:%02d %s-%s",strF[m.f],m.time.year, m.time.month, m.time.day, m.time.hour, m.time.min, m.time.sec, m.serie, m.name)))
		end
	end
end

m = params.device
m.time = os.date("*t", socket.gettime())
m.time.wday = m.time.wday - 1
m.now = socket.gettime()
--	local mymsg = sendmsg(m,"S"..m.serie.."B")
--	m.f = "0"
--	local mymsg = sendmsg(m,"S"..m.serie..m.f)
--	m.f = "A"
--	local mymsg = doblesendmsg(m,"S"..m.serie..m.f)
--	m.f = "B"
--	local mymsg = sendmsg(m,"S"..m.serie..m.f)
--	m.f = "XB"
--	local mymsg = sendmsg(m,"S"..m.serie..m.f)




--while 1 do
	m.cli = socket.udp()
	m.cli:settimeout(3,"t")
	m.cli:setpeername(m.host, m.port)
	m.f = params.cmd
	doblesendmsg(m,"S"..m.serie..params.cmd)
	m.cli:close()
	m.cli = nil
	printDL(5,"-------------------------------------------------")
--end
