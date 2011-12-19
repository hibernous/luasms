require("ctrls_common")
DEBUG = 5
function openMy()
	local host = "172.17.0.56"
	local connMy, serr = mysql:connect("molinetes","root", "pirulo", host)
	if not connMy then
--		printDL(2,"Error al conectar con MySql en Host: "..host)
		printDL(2,serr)
	end
	return connMy
end

function openMS(data)
	local dataSource = data
	local connMS, errText = mssql:connect(dataSource) 
	if not connMS then
		printDL(2,string.format("Error al conectar MS-SQL con ODBC DataSource '%s'",dataSource))
		printDL(2,errText)
--		os.exit(1)
	end
	return connMS
end

function tbMolinetes()
	local t = {}
	dbMol, dbErr = openMS("18")
	if dbMol == nil then os.exit(0) end
	sql = "SELECT CAST(Id AS VARCHAR(36)) AS uId, Descripcion, IP, Serie, Numero FROM Molinetes"
	local cur, serr = doSql(dbMol, sql)
	if serr then os.exit(0) end
	local row = cur:fetch ({}, "a")
	while row do
		local n = row.Numero
		if tonumber(row.Numero) then
			t[n] 			= {}
			t[n].uId		= row.uId
			t[n].numero		= row.Numero
			t[n].serie		= row.Serie
			t[n].name		= row.Descripcion
			t[n].host		= row.IP
			t[n].port		= 3010
			print(n, row.Numero, row.Serie, row.uId)
--
--
			t[n].lastreg    = {}
--
--
			t[n].fail		= {}
			t[n].fail["1"]	= 0
			t[n].fail["A"]	= 0
			t[n].fail["B"]	= 0
			t[n].fail["XB"]	= 0
			t[n].fail["XK"]	= 0
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
	return t
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
		local strReg = string.format("%s;%s;%s;%s\n", m.read.strFecha, m.read.Trj, m.serie, m.read.sensor)
		local oldReg, errtext, errcode = io.open("C:\\luatest\\oldfichadas.dat","a")
		if oldReg == nil then
			printDL(1, string.format("oldfichadas.dat '%s'", errtext))
		else
			local ok, errtext, errcode = oldReg:write(strReg)
			oldReg:close()
			if ok == true then
				printDL(4, string.format("oldfichadas.dat:'%s;%s;%s;%s'",m.read.strFecha, m.read.Trj, m.serie, m.read.sensor))
			else
				printDL(2, string.format("oldfichadas.dat: '%s'", errtext))
			end
		end
	end
end

local tbMol = tbMolinetes()
local conReg = openMy()
--[[
sql = string.format("SELECT * FROM `molinetes`.`ctrls_mov` where fecha between '2011-07-26' and '2011-07-30'")
local desde = 1
local limit = 100000
local cur, serr = conReg:execute(string.format("%s LIMIT %d, %d",sql,desde,limit))
if serr then
	print(serr)
end
while cur do
	local leyo = cur:numrows()
	if leyo > 0 then
		desde = desde + leyo
		local row = cur:fetch ({}, "a")
		while row do
			local m = tbMol[tonumber(row.idctrl)]
			m.read = {}
			if serr then 
				print(serr)
				os.exit(0)
			end
			m.read.strFecha = row.fecha
			m.read.sensor = row.sensor
			m.read.trj = row.tarjeta
			print(m.read.strFecha, m.serie, m.read.sensor, m.read.trj)
--			makeOldData(m)
			row = cur:fetch ({}, "a")
		end
		cur:close()
		print("Procesadas : ", desde-1)
		cur, serr = conReg:execute(string.format("%s LIMIT %d, %d",sql,desde,limit))
	else
		break
	end
end

]]
sql = [[
SELECT h.Fecha, h.Tarjeta, h.Molinete, h.Sensor, h.TpDoc, h.NumeroDocumento, h.Apellido, h.Nombre FROM (
SELECT
dbo.Fichadas.FechaHora AS Fecha,
(SELECT Numero FROM dbo.Tarjetas WHERE Id=dbo.Fichadas.Tarjeta) AS Tarjeta,
(SELECT Serie FROM dbo.Molinetes WHERE Id=dbo.Fichadas.Molinete) AS Molinete,
dbo.Fichadas.Sensor AS Sensor,
(SELECT Descripcion FROM dbo.TiposDocumento WHERE Ciudadanos.TipoDocumento = Id) AS TpDoc,
Ciudadanos.NumeroDocumento AS NumeroDocumento,
Ciudadanos.Apellido AS Apellido,
Ciudadanos.Nombre AS Nombre,
Ciudadanos.Foto AS Foto
FROM dbo.Fichadas
INNER JOIN dbo.Ciudadanos ON Fichadas.Ciudadano = Ciudadanos.Id ) h order by h.Fecha
]]
	local cur, serr = doSql(dbMol,sql)
	if cur then 
		local row, serr = cur:fetch({},"a")
		while row do
			row.Apellido = fixNames(row.Apellido)
			row.Nombre = fixNames(row.Nombre)
			row.Fecha = row.Fecha:sub(1,19)
			print(string.format("%s %10s %s %s %3s %8s %s %s",row.Fecha, row.Tarjeta, tostring(row.Molinete), row.Sensor, row.TpDoc, row.NumeroDocumento, row.Apellido, row.Nombre))
			row, serr = cur:fetch({},"a")
		end
	end
	
