json = require("json")
socket = require("socket")
require "luasql.odbc"
mssql = luasql.odbc()
require "luasql.mysql"
mysql = luasql.mysql()
DEBUG = 2

function printDL(level, ...)
	local lista = {...}
	local level = level or 99
	local ttipo = {"ERROR", "ERROR", "WARNING", "INFO"}
	local stipo = "DEBUG-INFO"
	if level < 5 then 
		stipo = ttipo[level]
	end
	if level <= DEBUG then
--		io.write(string.format("%s %s:%s %s ",os.date("%x %X",socket.gettime()), PROGRAM, FUNCTION,stipo))
		if level < 5 then
			io.write(string.format("%s %s",os.date("%x %X", socket.gettime()), stipo))
		else
			io.write("\t")
		end
		if lista then
			for i=1, #lista do
				io.write(" "..tostring(lista[i]))
			end
		end
		io.write("\n")
	end
end

function dbConStatus(dbCon)
	if dbCon == nil then
		return false
	end
	if tostring(dbCon):match("(closed)")
	then
		return false
	else
		return true
	end
end

function openMy()
	local host = "172.17.0.56"
	local connMy, serr = mysql:connect("molinetes","root", "pirulo", host)
	if not connMy then
		print("Error al conectar con MySql en Host: "..host)
		print(serr)
	end
	return connMy
end

function openMS(data)
	local dataSource = data
	local connMS = mssql:connect(dataSource) 
	if not connMS then
		printDL(2,string.format("Error al conectar MS-SQL con DataSource '%s'",dataSource))
--		os.exit(1)
	end
	return connMS
end

function doSql(dbCon,str)
	local rslt, serr = nil, nil
	if dbConStatus(dbCon) then
		rslt, serr = dbCon:execute(str)
		if serr then
			printDL(2,string.format("doSql:'%s'\tstatement: '%s'", serr, str))
			if serr:match("Error en el vínculo de comunicación") 
			or serr:match("MySQL server has gone away")
			then
				dbCon:close()
			end
		end
	end
	return rslt, tostring(dbCon)
end

function oldMovs(m)
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
	local cur, serr = doSql(dbMS,sql)
	local row = cur:fetch({}, "a")
	if row then
--		print(row.Tarjeta, row.Ciudadano)
	else 
		print(m.read.trj, m.read.strFecha)
		sql = string.format("SELECT CAST(Id AS VARCHAR(36)) AS Tarjeta, Numero FROM Tarjetas WHERE Numero = '%s'", m.read.trj)
		local cur, serr = doSql(dbMS, sql)
		if cur then 
			local row = cur:fetch({},"a")
			print(row.Tarjeta, row.Numero)
			sql = string.format([[
			SELECT TOP 1 CAST(Ciudadano AS VARCHAR(36)) Ciudadano FROM
			(
				SELECT Ciudadano FROM Personal WHERE Tarjeta = CAST('%s' AS UNIQUEIDENTIFIER)
				UNION
				SELECT Ciudadano FROM Visitantes WHERE Id IN
					(SELECT Visitante FROM Visitantes_Tarjetas WHERE Tarjeta = CAST('%s' AS UNIQUEIDENTIFIER) AND Baja is null)
			) AS Ciudadano
			]], row.Tarjeta, row.Tarjeta)
			sql = string.format([[
			SELECT TOP 1 CAST(Ciudadano AS VARCHAR(36)) Ciudadano FROM
			(
				SELECT Ciudadano FROM HST_Personal WHERE Tarjeta = CAST('%s' AS UNIQUEIDENTIFIER)
				UNION
				SELECT Ciudadano FROM Visitantes WHERE Id IN
					(SELECT Visitante FROM HST_Visitantes_Tarjetas WHERE Tarjeta = CAST('%s' AS UNIQUEIDENTIFIER))
			) AS Ciudadano
			]], row.Tarjeta, row.Tarjeta)
			local sql = string.format([[SELECT * FROM `molinetes`.`trj_mov` where tarjeta='%s' ORDER By idtrj_mov DESC LIMIT 1]],m.read.trj)
			ccur, serr = doSql(dbMy, sql)
			if ccur then
				local row = cur:fetch({}, "a")
				if row then
					if row.tipo == "ASIGNA" then
						print("","",row.a)
					end
				else
					print("","","No ciudadano")
				end
				ccur:close()
			end
			cur:close()
		end
		
	end
	cur:close()
end

t1 = socket.gettime()
dbMS = openMS("18")
t2 = socket.gettime()
print(t2-t1)
dbMy = openMy()
print(socket.gettime()-t2)
--cur, dberr = doSql(dbMS,"SELECT Apellido, Nombre FROM Ciudadanos")
local m = {}
m.read = {}

local cur, dberr = doSql(dbMy,"SELECT * FROM registros1")
local row = cur:fetch({},"a")

while row do
	m.read.trj = row.TarjetaId
	m.read.strFecha = row.fecha
	m.read.sensor = row.sensor
	m.read.moli = row.controler
	oldMovs(m)
--	print(m.read.strFecha, m.read.trj, m.read.moli, m.read.sensor)
	row = cur:fetch({}, "a")
end
