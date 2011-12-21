require "luasql.odbc"
mssql = luasql.odbc()

local es	= {}
es["0"] 	= "Entra"
es["1"] 	= "Sale"
es["2"]		= "Buzon-Sale"
es["3"]		= "Desconocido"
es["4"]		= "No Entra"
es["5"]		= "No Sale"
es["6"]		= "Buzon-No Sale"


function openMy()
	print("openMy()")
--	local host = "172.17.0.56"
	local host = "10.10.8.249"
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

