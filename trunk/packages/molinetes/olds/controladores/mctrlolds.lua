require("ctrls_common")
require "luasql.odbc"
mssql = luasql.odbc()

DEBUG 	= tonumber(arg[1]) or 2
PROGRAM = arg[0]

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

local conReg = openMy()

--[[
function connectMolinete(r)
	if socket.gettime() - r.reopen < 0 then 
		return nil
	end
	cli, serr = socket.connect(r.host, r.port)
	if serr then
		r.reopen = socket.gettime() + 90
		print(string.format("Error: %s al conectar %s en la ip '%s' puerto %s",serr, r.name, r.host, r.port))
		r.failopen = r.failopen + 1
	else
		r.reopne = socket.gettime()
		cli:settimeout(1,"t")
		set:insert(cli, r)
		print(string.format("Conectado a %s en la ip '%s' puerto %s", r.name, r.host, r.port))
	end
	return cli
end
]]

function tbMolinetes()
	local t = {}
--[[
	dbMol, dbErr = openMS("moli")
	if dbMol == nil then 
		print(dbErr)
		os.exit(0) 
	end
	sql = "SELECT CAST(Id AS VARCHAR(36)) AS uId, Descripcion, IP, Serie, Numero FROM Molinetes"
	local cur, serr = doSql(dbMol, sql)
	while row do
		local n = row.Serie
		row.Numero = tonumber(row.Numero)
		if row.Numero < 9 then
			t[n] 			= {}
			t[n].uId		= row.uId
			t[n].numero		= row.Numero
			t[n].serie		= row.Serie
			t[n].name		= row.Descripcion
			t[n].host		= row.IP
			t[n].port		= 3010
			t[n].type		= "Macronet"
--
--
			t[n].lastreg    = {}
--
--
			t[n].fail		= {}
			t[n].fail["0"]	= 0
			t[n].fail["1"]	= 0
			t[n].fail["A"]	= 0
			t[n].fail["B"]	= 0
			t[n].fail["XB"]	= 0
			t[n].fail["XK"]	= 0
			t[n].fail["XS"]	= 0
			t[n].fail["CM"]	= 0
--
--			t[n].timeout	= 0
--			t[n].waiting	= 0
--			t[n].waiting	= 0
--			t[n].failopen	= 0
--			t[n].reopen		= 0
--			t[n].last		= 0
--			t[n].msg		= ""
--
		end
		row = cur:fetch ({}, "a")
	end
	cur:close()
]]
	local sql = "SELECT * FROM `molinetes`.`ctrls` WHERE activo='1'"
	local cur, dbErr = doSql(conReg,sql)
	if dbErr then 
		print(dbErr)
		os.exit(0) 
	end
	local row = cur:fetch ({}, "a")
	while row do
		local n = row.id
		row.Numero = tonumber(row.idctrls)
		t[n] 			= {}
		t[n].name		= row.name
		t[n].mac		= row.mac
		t[n].host		= row.ip
		t[n].type		= row.tipo
		t[n].numero		= row.Numero
		t[n].serie		= row.id
		t[n].port		= 3010
		t[n].protocol	= row.protocol
--
--
		t[n].lastreg    = {}
--
--
		t[n].fail		= {}
		t[n].fail["0"]	= 0
		t[n].fail["1"]	= 0
		t[n].fail["A"]	= 0
		t[n].fail["B"]	= 0
		t[n].fail["XB"]	= 0
		t[n].fail["XK"]	= 0
		t[n].fail["XS"]	= 0
		t[n].fail["CM"]	= 0
--
--			t[n].timeout	= 0
--			t[n].waiting	= 0
--			t[n].waiting	= 0
--			t[n].failopen	= 0
--			t[n].reopen		= 0
--			t[n].last		= 0
--			t[n].msg		= ""
--
		row = cur:fetch ({}, "a")
	end
	cur:close()
	return t
end

function sendmsg(m,s)
	local stx="" -- string.char(2)
	local etx="" -- string.char(3)
	local msg = stx..s..etx
	msg = msg..parityBit(msg)
	printDL(7,"Envia:", msg)
	local bs, serr = m.cli:send(msg)
	if serr then
		printDL(1,string.format("Error %s \n\tal enviar comando '%s' a %s", serr, msg, m.name))
	end
	return bs
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
	if m.rspta then
--		printDL(5,string.format("%s decodeMsg '%s' id:%s-%s", strF[m.f], m.rspta,m.serie, m.name))
		m.timeout = 0
		m.cli:send(string.char(6))
		local parity = m.rspta:sub(-1)
		local msg = m.rspta:sub(2,-2)
		if parityBit(msg) == parity then
			_, _, r.code, r.sensor = msg:find("(.)(.)%d%d%d%d%d%d%d%d")
			if r.code == "A" then
				_, _, r.code, r.sensor, r.month, r.day, r.hour, r.min, r.molId = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d)")
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
				_, _, r.code, r.sensor, r.month, r.day, r.hour, r.min, r.cnt = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d)")
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
			elseif r.code == "2" then
				_, _, r.code, r.sensor, r.month, r.day, r.hour, r.min, r.trj, r.molId, r.secuencia = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d%d%d%d%d%d)(%d%d%d%d%d)(%d%d)")
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
					_, _, r.code, r.sensor, r.month, r.day, r.hour, r.min, r.trj = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d%d%d%d%d%d)")
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
				m.fail[m.f] = m.fail[m.f] + 1
				local strerr = string.format("%s: Rspta No Procesada:'%s' (%d) id:%s-%s", strF[m.f], addslashes((r.msg or "")), m.fail[m.f], m.serie, m.name)
				printDL(errorLevel(m,strerr))
			end
		else
			m.fail[m.f] = m.fail[m.f] + 1
			local strerr = string.format("%s: Invalid response:'%s' count(%d) id:%s-%s", strF[m.f], addslashes(m.rspta), m.fail[m.f], m.serie, m.name)
			printDL(errorLevel(m,strerr))
		end
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

function setdate(m)
	local mymsg = sendmsg(m, string.format("S%s1%02d%02d%02d%d%02d%02d%02d",m.serie,string.sub(m.time.year,-2), m.time.month, m.time.day, m.time.wday, m.time.hour, m.time.min, m.time.sec))
	m.f = "1"
	m.rspta, m.serr = m.cli:receive()
	if m.serr then
		m.fail[m.f] = m.fail[m.f] + 1
		printDL(errorLevel(m,string.format("%s: Socket:%s count(%d) %s-%s",strF[m.f], m.serr, m.fail[m.f], m.serie, m.name)))
	else
		m.cli:send(string.char(6))
		m.fail[m.f] = 0
		printDL(errorLevel(m,string.format("%s OK: %04d-%02d-%02d %02d:%02d:%02d %s-%s",strF[m.f],m.time.year, m.time.month, m.time.day, m.time.hour, m.time.min, m.time.sec, m.serie, m.name)))
	end
	socket.sleep(1)
end

function checkHora(m)
	local mymsg = sendmsg(m, "S"..m.serie.."A")
	m.f = "A"
	m.time = os.date("*t", socket.gettime())
	m.time.wday = m.time.wday - 1
	m.rspta, m.serr = m.cli:receive()
	t = decodeMsg(m)
	if t.status then
		if not (t.hour == m.time.hour
		and t.min == m.time.min
		and t.month == m.time.month
		and t.day == m.time.day) 
		then
			t.hour = m.time.hour
			t.min = m.time.min
			t.month = m.time.month
			t.day = m.time.day
			setdate(m)
		end
		checkFichadas(m)
	end
end
	
function checkFichadas(m)
	local mymsg = sendmsg(m,"S"..m.serie.."B")
	m.f = "B"
	m.rspta, m.serr = m.cli:receive()
	t = decodeMsg(m)
	if t.status and t.cnt then
		if t.cnt > 0 then
			getRegistracioes(m)
		end
	else
		print("CheckFichas",t.status )
	end
end

set = newset()
local tbMol = tbMolinetes()
local skt, b = socket.connect("172.17.0.56", "8181")
if skt == nil then 
	print(b) 
	os.exit(0)
end

tcontrol = {}
tcontrol.type = "setObject"
tcontrol.object = "controler"
tcontrol.id = "1"
tcontrol.name = "Molinetes M.T. Alvear"
tcontrol.description = "Control de entrada Salida general de la casa de Gobierno"
tcontrol.devices = tbMol

skt:send(json.encode(tcontrol).."\n")

function makeNewData(m)
	local searchTrj = string.format([[SELECT * FROM `molinetes`.`trj_mov` where tarjeta='%s' ORDER By idtrj_mov DESC LIMIT 1]],m.read.trj)
	local cur, serr = doSql(conReg,searchTrj)
print(m.read.trj, serr)
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
				local cur, serr = doSql(conReg,searchPrs)
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
	skt:send(json.encode(m.read).."\n")
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
	local cur, serr = doSql(dbMol,sql)
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
			local rslt, serr = doSql(dbMol, sql)
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
				local rslt, serr = doSql(dbMol, sql)
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
	local cur, serr = doSql(conReg, sql)
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
			local rslt, serr = doSql(conReg, sql)
			if rslt then
				if m.read.sensor == 2 then
					local sql = string.format([[
INSERT INTO trj_mov (fecha, tarjeta, tipo, de, a) 
	VALUES ('%s', '%s', '%s', '%s', '%s')
]], m.read.strFecha, m.read.trj, "BUZON", (m.read.persona or "NULL"), m.serie)
					local rslt, serr = doSql(conReg, sql)
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

function getRegistracioes(m)
	local mymsg = sendmsg(m,"S"..m.serie.."XB")
	m.f = "XB"
	m.rspta, m.serr = m.cli:receive()
	printDL(5,"\tRegistraciones",m.rspta, m.serr)
	if m.serr == nil then 
		t = decodeMsg(m)
		if t.status and t.secuencia then
			local fecha = string.format("%d-%02d-%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, 0)
		end
		while t.secuencia and t.status do
--		if t.secuencia and t.status then
			if saveData(m,t) == true then
				m.paso = true
				local mymsg = sendmsg(m,string.format("S%05dXK%02d",m.serie,t.secuencia))
				m.cli:send(mymsg)
				m.f = "XK"
				m.rspta, m.serr = m.cli:receive()
				t = decodeMsg(m)
--printDL(5,"\tRegistraciones",m.rspta, m.serr)
			else
				t.status = nil
				t.secuencia = nil
			end
		end
	end
end

function webInfo(m)
	t = m
	t.event = "molinetestatus"
	for k,v in pairs(m.fail) do
		t[k] = v
	end
	t.type = "molinfo"
	skt:send(json.encode(t).."\n")
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
	local cur, serr = doSql(dbMol, strSQL)
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
				local rslt, serr = doSql(dbMol, strSQL)
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

	while 1 do
		for n, m in pairs(tcontrol.devices) do
			m.paso = false
			m.time = os.date("*t", socket.gettime())
			m.time.wday = m.time.wday - 1
			m.now = socket.gettime()
			m.cli = socket.udp()
			m.cli:settimeout(5,"t")
			m.cli:setpeername(m.host, m.port)
			showErrors(m)
--			checkCommands(m)
--[[
			local mymsg = sendmsg(m, "S"..m.serie.."0")
			m.f = "0"
			m.rspta, m.serr = m.cli:receive()
			if m.rspta == string.char(6) then
				m.fail[m.f] = 0
			else
				printDL(5, "No respondio a "..strF[m.f])
				m.fail[m.f] = m.fail[m.f] + 1
			end
			--t = decodeMsg(m)
]]
--			checkHora(m)
			getRegistracioes(m)
			local mymsg = sendmsg(m, "S"..m.serie.."XS")
--[[
--			setdate(m)
			local mymsg = sendmsg(m, "S"..m.serie.."XS")
			m.f = "XS"
			m.rspta, m.serr = m.cli:receive()
			if m.rspta == string.char(6) then
				m.fail[m.f] = 0
			else
				printDL(5, "No respondio a "..m.f)
				m.fail[m.f] = m.fail[m.f] + 1
			end
			checkFichadas(m)
			local mymsg = sendmsg(m, "S"..m.serie.."XS")
			m.f = "XS"
			m.rspta, m.serr = m.cli:receive()
			if m.rspta == string.char(6) then
				m.fail[m.f] = 0
			else
				printDL(5, "No respondio a "..m.f)
				m.fail[m.f] = m.fail[m.f] + 1
			end
--			t = decodeMsg(m)
]]
---- Esto es para probar la carga de tarjetas
--[[
			m.f = "X+T"
			local mymsg = sendmsg(m, "S"..m.serie..m.f.."0228033126")
			m.rspta, m.serr = m.cli:receive()
			if m.rspta == string.char(6) then
				print(m.f.." Ok")
--				m.fail[m.f] = 0
			else
				print(m.f.." No respondio")
--				m.fail[tostring(m.f)] = m.fail[m.f] + 1
			end
--			t = decodeMsg(m)
]]
			m.cli:close()
			m.cli = nil
			if m.paso == true then
				t = m
				t.event = "EntraSale"
				t.type = "molinfo"
				skt:send(json.encode(t).."\n")
			end
			webInfo(m)
		end
		printDL(5,"-------------------------------------------------")
		socket.sleep(5)
	end
