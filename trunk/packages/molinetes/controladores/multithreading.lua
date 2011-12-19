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
require("lanes")
require("ctrls_common")
require "luasql.odbc"

local json = json
local socket = socket
local errorLevel = errorLevel
local printDL = printDL
local dbConStatus = dbConStatus
local doSql = doSql

local mssql = luasql.odbc()

local es	= {}
es["0"] 	= "Entra"
es["1"] 	= "Sale"
es["2"]		= "Buzon-Sale"
es["3"]		= "Desconocido"
es["4"]		= "No Entra"
es["5"]		= "No Sale"
es["6"]		= "Buzon-No Sale"


local function openMy()
	print("openMy()")
--	local host = "172.17.0.56"
	local host = "127.0.0.1"
	local connMy, serr = mysql:connect("molinetes","root", "pirulo", host)
	if not connMy then
--		printDL(2,"Error al conectar con MySql en Host: "..host)
		printDL(2,serr)
	end
	return connMy
end

local function openMS(data)
	local dataSource = data
	local connMS, errText = mssql:connect(dataSource,"sa","vamosGlobant") 
	if not connMS then
		printDL(2,string.format("Error al conectar MS-SQL con ODBC DataSource '%s'",dataSource))
		printDL(2,errText)
--		os.exit(1)
	end
	return connMS
end

local function makeNewData(m)
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

local function makeOldData (m)
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

local function saveData(m)
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


local strF		= {}
strF["0"]	= "GET_REGISTRA"
strF["1"]	= "SET_HORA"
strF["9"]	= "READ_MEM"
strF["A"]	= "CHK_HORA"
strF["B"]	= "CHK_FICHADAS"
strF["W"]	= "GRABA_MEMORIA"
strF["XB"]	= "GET_FICHADA"
strF["XK"]	= "DEL_FICHADA"
strF["XS"]	= "DET_FICHADA"

local cmdsec = {"0","A","1","9","B","W","XB","XK","XS"}

local es	= {}
es["0"] 	= "Entra"
es["1"] 	= "Sale"
es["2"]		= "Buzon-Sale"
es["3"]		= "Desconocido"
es["4"]		= "No Entra"
es["5"]		= "No Sale"
es["6"]		= "Buzon-No Sale"



local function checkHora(m)
	m.time = os.date("*t", socket.gettime())
	m.time.wday = m.time.wday - 1
--	m.rspta, m.serr = params.cli:receive()
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
			else 
				m.timelastdev = socket.gettime()
			end
		end
	end
end
	
local function webInfo(m)
	local t = nil
	for k, r in pairs(m.status) do
		if type(r) == "table" then
			if m.prev[k].msg ~= r.msg then
				if t == nil then t = {} end
				if t[k] == nil then t[k] = {} end
				for l, a in pairs(r) do
					t[k][l] = a
				end
--[[
			else
				if m.prev[k].errorpercent ~= r.errorpercent then
					if t == nil then t = {} end
					if t[k] == nil then t[k] = {} end
					for l, m in pairs(r) do
						t[k][l] = m
					end
				end
]]
			end
			for i, v in pairs(r) do
				m.prev[k][i] = v
			end
		else
			if r ~= m.prev[k] then
				if t == nil then t = {} end
				t[k] = r
			end
			m.prev[k] = r
		end
	end
	if t then		
		info = {}
		info.event	= "molinetestatus"
		info.id		= m.id
--		info.numero = m.numero
		info.start	= m.status.start
--		info.serie	= m.serie
--		info.name	= m.name
--		info.host	= m.host
--		info.type	= m.type
		info.data = t
		info.data = m.status.hora 
		info.data = m.status.entraron
		info.data = m.status.salieron
		info.data = m.status.ultima
		srvInfoSend(params,info)
	end
end

local function showErrors(m)
	local str = string.format("id:%s host:%s port:%s Err: ", m.serie, m.host, m.port)
	for k,v in pairs(m.fail) do
		str = str .. string.format("%s:%d ",k,v)
	end
	printDL(5,"\n")
	printDL(5,str)
end

local function checkCommands(m)
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
			m.rspta, m.serr = params.cli:receive()
			m.f = "CM"
			if m.rspta == string.char(6) then
				strSQL = string.format("DELETE FROM ComandosDiferidos WHERE Id='%s'", t.cmdId)
				local rslt, serr = doSql(params.msDB, strSQL)
				m.status[strF[m.f]].fail = 0
			else
				m.status[strF[m.f]].fail = m.status[strF[m.f]].fail + 1
				local strerr = "Error al enviar comando "..t.cmdstr
				printDL(errorLevel(m,strerr))
				break
			end
		end
	end
end

local function get_moldata(sql)
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
		t.id		= row.idctrl
		t.name		= row.name
		t.mac		= row.mac
		if params.molip and params.molip ~= row.ip then
			print("IP no coinside con la almacenada en la base de datos")
			row.ip = params.molip
		end
		t.host		= row.ip
		t.type		= row.tipo
		t.numero	= row.idctrl
		t.serie		= row.id
		t.port		= row.port or 3010
		t.protocol	= row.protocol
		t.timelastset = 0
--
--
		t.lastreg    = {}
--
--
		t.fail			= {}
		t.count			= {}
		t.status		= {}
		t.prev			= {}
		t.status.start	= socket.gettime()
		t.prev.start	= socket.gettime()
		t.status.hora	= 0
		t.prev.hora	= 0
		t.status.entraron = 0
		t.prev.entraron = 0
		t.status.salieron = 0
		t.prev.salieron = 0
		t.status.ultima = 0
		t.prev.ultima = 0
		for _, cmd in ipairs(cmdsec) do
			t.count[cmd] = 0
			t.fail[cmd] = 0
			t.status[strF[cmd]] = { msg="Desconocido", hora=socket.gettime(), detalle="Inicio programa controlador", errorpercent = "0.00%", count=0, fail=0}
			t.prev[strF[cmd]] = { msg="Desconocido", hora=socket.gettime(), detalle="Inicio programa controlador", errorpercent = "0.00%", count=0, fail=0}
		end
		sql = string.format("SELECT CAST(Id AS VARCHAR(36)) AS uId FROM Molinetes WHERE Serie='%s'",t.serie)
		local cur, serr = doSql(params.msDB, sql)
		local row = cur:fetch ({}, "a")
		t.uId = row.uId
	end
	cur:close()
	return t
end

local function doblesendmsgNoAnswer(m,s)
	openUDP(m)
	
	local bs, serr = dsendUDP(m,s)
	if bs == s:len()+3 then
		m.rspta = nil
		leeUDP(m)
		if m.rspta == nil then
			m.status[strF[m.f]].fail = m.status[strF[m.f]].fail + 1
--			setStatus(m,m.serr,string.format("%s No responde ACK",strF[m.f]))
			setStatus(m,m.serr,"No responde ACK")
			errorLevel(m,string.format("%s Error %s count(%s)", strF[m.f],m.serr,m.status[strF[m.f]].fail))
		else
			setStatus(m,"OK","")
			return m
		end
	end
	return nil
end

local function setStatus(m,msg,detalle)
	m.status[strF[m.f]].msg = msg
	m.status[strF[m.f]].detalle = detalle
	if m.prev[strF[m.f]].msg ~= msg then
		m.status[strF[m.f]].hora = socket.gettime()
	end
	m.status[strF[m.f]].errorpercent = string.format("%5.2f",m.status[strF[m.f]].fail/m.status[strF[m.f]].count*100).."%"
end

local function doblesendmsg(m,s)
	openUDP(m)
	local bs, serr = dsendUDP(m,s)
	if bs == s:len()+3 then
		m.rspta = nil
		leeUDP(m)
--		closeUDP(m)
		if m.rspta == nil then
			m.status[strF[m.f]].fail = m.status[strF[m.f]].fail + 1
--			m.status[cmd] = { msg="Desconocido", hora=os.date("%c"), detalle="Inicio programa controlador", errorpercent = 0}
--			setStatus(m,m.serr,string.format("%s No responde ACK",strF[m.f]))
			setStatus(m,m.serr,"No responde ACK")
			errorLevel(m,string.format("%s Error %s No recibe ACK count(%s)", strF[m.f],m.serr,m.status[strF[m.f]].fail))
		elseif m.rspta == string.char(6) then
			leeUDP(m) -- al recibir char(6) hay que hacer otra lectura porque la respuesta puede venir en dos tantadas
			setStatus(m,"OK","") -- por más que no venga algo más al haber recibido el char(6) se considera respuesta correcta
			if m.rspta then
				return decodeMsg(m) -- Vino algo más entonces hay que procesarlo
			end
		elseif m.rspta:sub(1,1) == string.char(6) then
			m.rspta = m.rspta:sub(2)
			setStatus(m,"OK","")
			return decodeMsg(m)
		end
	end
	return nil
end

local function dsendUDP(m,s)
	local stx="" -- string.char(2)
	local etx="" -- string.char(3)
	local msg = stx..s..etx
	msg = msg..parityBit(msg)
	printDL(7,"Envia:", strF[m.f], msg)
	m.status[strF[m.f]].count = m.status[strF[m.f]].count + 1
	local bs, serr = params.cli:send(msg)
	local bs, serr = params.cli:send(msg)
	if serr then
		printDL(1,string.format("Error %s \n\tal enviar comando '%s' a %s", serr, msg, m.name))
	end
	return bs, serr
end

local function sendUDP(m,s)
	local stx="" -- string.char(2)
	local etx="" -- string.char(3)
	local msg = stx..s..etx
	msg = msg..parityBit(msg)
	printDL(7,"Envia:", strF[m.f], msg)
	m.status[strF[m.f]].count = m.status[strF[m.f]].count + 1
	local bs, serr = params.cli:send(msg)
	if serr then
		printDL(1,string.format("Error %s \n\tal enviar comando '%s' a %s", serr, msg, m.name))
	end
	return bs, serr
end

local function sendcmd(m,s)
	printDL(7,"Envia:", s)
	local bs, serr = params.cli:send(s)
	if serr then
		printDL(1,string.format("Error %s \n\tal enviar comando '%s' a %s", serr, s, m.name))
	end
	return bs
end

local function decodeMsg(m)
	local r = {}
	r.year = m.time.year
	r.wday = m.time.wday
	r.sec = m.time.sec
	r.status = false

	if m.serr == nil then
--		printDL(5,string.format("%s decodeMsg '%s' id:%s-%s", strF[m.f], m.rspta,m.serie, m.name))
		m.timeout = 0
		local parity = m.rspta:sub(-1)
		local msg = m.rspta:sub(2,-3)
--		print(msg)
--		if parityBit(msg) == parity then
			_, _, r.code, r.sensor = msg:find("(.)(.)%d%d%d%d%d%d%d%d")
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
					r.status = true
					local strerr = string.format("%s: %04d-%02d-%02d %02d:%02d:%02d %s-%s", strF[m.f], r.year, r.month, r.day, r.hour, r.min, r.sec, m.serie, m.name)
					m.status.hora = string.format("%04d-%02d-%02d %02d:%02d",r.year, r.month, r.day, r.hour, r.min)
					printDL(5,strerr)
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
					r.status = true
					m.status.ultima = string.format("%04d-%02d-%02d %02d:%02d", r.year, r.month, r.day, r.hour, r.min)
					r.cnt = tonumber(r.cnt)
					printDL(5,strerr)
--					printDL(5,r.code, r.sensor, r.month, r.day, r.hour, r.min, tonumber(r.cnt))
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
						r.status = true
						r.trj = tonumber(r.trj)
						printDL(5, strerr)
						printDL(5,r.code, r.sensor, r.month, r.day, r.hour, r.min, r.trj)
					end
				end
			else
--				m.status[strF[m.f]].fail = m.status[strF[m.f]].fail + 1
				local strerr = string.format("%s: Rspta No Procesada:'%s' (%d) id:%s-%s", strF[m.f], addslashes((r.msg or "")), m.status[strF[m.f]].fail, m.serie, m.name)
				printDL(errorLevel(m,strerr))
			end

--		else
--			m.status[strF[m.f]].fail = m.status[strF[m.f]].fail + 1
--			local strerr = string.format("%s: Invalid response:'%s' count(%d) id:%s-%s", strF[m.f], addslashes(m.rspta), m.status[strF[m.f]].fail, m.serie, m.name)
--			printDL(errorLevel(m,strerr))
--		end

	else
		local strerr = string.format("%s: Socket:%s count(%d) %s-%s", strF[m.f], m.serr, m.status[strF[m.f]].fail, m.serie, m.name)
		printDL(errorLevel(m,strerr))
	end
	if r.month then r.month = tonumber(r.month) end
	if r.day then r.day = tonumber(r.day) end
	if r.hour then r.hour = tonumber(r.hour) end
	if r.min then r.min = tonumber(r.min) end
	m.read = r
	return r
end

local function checkFichadas(m)
	m.f = "B"
	local mymsg = doblesendmsg(m,"S"..m.serie..m.f)
end

local function getRegistracioes(m)
	m.f = "XB"
	local t = doblesendmsg(m,"S"..m.serie..m.f)
	if t then
--		if t.secuencia and t.status then			-- este es para leer de a una fichada por pasada
		while t and t.secuencia and t.status do 	-- este es para leer todas las posibles por pasada
			if saveData(m,t) == true then
				m.paso = true
				if m.read.sensor == "0" then m.status.entraron = m.status.entraron + 1
				elseif m.read.sensor == "1" then m.status.salieron = m.status.salieron + 1
				elseif m.read.sensor == "2" then m.status.salieron = m.status.salieron + 1
				end
				m.f = "XK"
				local mymsg = doblesendmsg(m,string.format("S%05dXK%02d",m.serie,t.secuencia))
				m.f = "XB"
				t = doblesendmsg(m,"S"..m.serie..m.f)
			else
				t.status = nil
				t.secuencia = nil
			end
		end
	end
end

local function setdate(m)
	local tiempo = socket.gettime()
	local hora = os.date("*t", tiempo)
	
	if tiempo - m.timelastset > 60 or hora.sec <= 10 then
		m.f = "1"
		local mymsg = doblesendmsgNoAnswer(m, string.format("S%s%s%02d%02d%02d%d%02d%02d%02d",m.serie,m.f,string.sub(m.time.year,-2), m.time.month, m.time.day, m.time.wday, m.time.hour, m.time.min, m.time.sec))
		if m.serr then
--			m.status[strF[m.f]].fail = m.status[strF[m.f]].fail + 1
--			printDL(errorLevel(m,string.format("%s: Socket:%s count(%d) %s-%s",strF[m.f], m.serr, m.status[strF[m.f]].fail, m.serie, m.name)))
		else
			m.timelastset = socket.gettime()
--			printDL(errorLevel(m,string.format("%s OK: %04d-%02d-%02d %02d:%02d:%02d %s-%s",strF[m.f],m.time.year, m.time.month, m.time.day, m.time.hour, m.time.min, m.time.sec, m.serie, m.name)))
		end
	end
end

local function openUDP(m)
	closeUDP(m)
	params.cli = socket.udp()
	params.cli:settimeout(2,"t")
	params.cli:setpeername(m.host, m.port)
end

local function closeUDP(m)
	if params.cli then
		params.cli:close()
		params.cli = nil
	end
end

local function leeUDP(m)
	local c = 0
	m.rspta = nil
	m.serr = nil
	while m.rspta == nil and c < 2 do
		m.rspta, m.serr = params.cli:receive()
		c = c+1
	end
	return m.rspta, m.serr
end

local function connectInfoSrv(params)
	params.srvskt, b = socket.connect(params.srvip, params.srvport)
	if params.srvskt then
		params.srvskt:settimeout(1,"t")
		local tcontrol = {}
		tcontrol.type = "setObject"
		tcontrol.object = "controler"
		tcontrol.device = {}
		for k, v in pairs(params.device) do
			if type(v) ~= "table" then
				tcontrol.device[k] = v
			end
		end
		refreshInfo()
		local data = json.encode(tcontrol).."\n"
		params.srvskt:send(data)
	else
		print(b)
	end
end

local function srvInfoSend(params, t)
	if params.srvInfo then
		if params.srvskt == nil then
			connectInfoSrv(params)
			if params.srvskt == nil then
				print("No se envía info"..json.encode(t))
				return
			end
		end
		local data = json.encode(t).."\n"
		local send, serr = params.srvskt:send(data)
		print("Enviado "..tostring(send).." Error: ".. tostring(serr))
--[[
		if serr == "closed" then
			params.srvskt:close()
			params.srvskt = nil
		end
]]
	end
end

local function processSrvMsg(str)
	local msg = json.decode(str)
	if msg.type == "GET_INFO" then
		refreshInfo()
	end
end

local function srvInfoReceive(params)
	if params.srvInfo then
		if params.srvskt then
			local str, serr = params.srvskt:receive()
			if str then
				processSrvMsg(str)
			end
			if serr == "closed" then
				params.srvskt:close()
				params.srvskt = nil
				connectInfoSrv(params)
			end
		else
			print("serInfoReceive socket is nil")
				connectInfoSrv(params)
		end
	end
end

local function refreshInfo()
	params.device.prev.hora = ""
	params.device.prev.entraron = ""
	params.device.prev.salieron = ""
	params.device.prev.ultima = ""
	
	for _, cmd in ipairs(cmdsec) do
		params.device.prev[strF[cmd]] = { msg="Desconocido", hora=socket.gettime(), detalle="Inicio programa controlador", errorpercent = 0, count=0, fail=0}
	end
end

local function my(molid, srvip, srvport)
DEBUG 	= 7
params = {}
params.program=arg[0]
params.srvInfo = nil
params.srvip = srvip
params.srvport = srvport
params.molid = molid
print("Ejecutando molinete "..molid)
--[[
for k, v in pairs(arg) do
--	print(k,v)
	if k > 0 then
		_, _, name, value = string.find(v,"([^=]+)=(.+)")
		params[name]=value
	end
end
]]
params.myDB = openMy()
print(params.myDB)
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
	params.srvInfo = true
	connectInfoSrv(params)
end

if params.srvskt == nil then
	print("Mierda")
	os.exit(0)
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
m.f = "W"
--local mymsg = doblesendmsgNoAnswer(m, string.format("S%s%s902800000A00080FD27831625349772EDBAE",m.serie,m.f))
local mymsg = doblesendmsgNoAnswer(m, string.format("S%s%s90330A",m.serie,m.f)) -- Esta secuencia setea el molinete para que lea los 10 numeros de las tarjetas
lastfullinfo = socket.gettime()
while 1 do
	print("loop")
	m.paso = false
	checkHora(m)
	setdate(m)
	getRegistracioes(m)
	checkFichadas(m)
	srvInfoReceive(params)
	if m.paso == true then
		local t = {}
		t.event = "EntraSale"
		t.type = "molinfo"
		srvInfoSend(params, t)
	end
	if socket.gettime() - lastfullinfo > 300 then 
		refreshInfo() 
		lastfullinfo = socket.gettime()
	end
	webInfo(m)
	printDL(5,"-------------------------------------------------")
	socket.sleep(1)
end
end

test = lanes.gen("*",{globals = _G}, my) 
a = test(1,"172.17.0.56","8181")
print(a)
--test(2,"172.17.0.56","8181")
--test(3,"172.17.0.56","8181")
--test(4,"172.17.0.56","8181")
--test(5,"172.17.0.56","8181")
--test(6,"172.17.0.56","8181")
--test(7,"172.17.0.56","8181")
--test(8,"172.17.0.56","8181")
