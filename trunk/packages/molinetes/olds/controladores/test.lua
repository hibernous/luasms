require "luasql.odbc"
mssql = luasql.odbc()

function openMS(data)
	local dataSource = data
	local connMS = mssql:connect(dataSource) 
	if not connMS then
		print("Error al conectar MS-SQL con DataSource '"..dataSource)
		os.exit(1)
	end
	return connMS
end

dbMol = openMS("18")
fecha = "2000-01-01 11:11:11"
trj="1065740"
sensor="0"
Molinete="3a15226a-4534-434e-ab8e-7cb5096db2e5"
sql2 = string.format(
[[
DECLARE	@return_value int
DECLARE @fecha DATETIME
SET @fecha = CONVERT (DATETIME, '%s', 120)

EXEC @return_value = [molinetes].[dbo].[dispositivos_GuardarFichada]
		@FechaHora = @fecha,
		@Tarjeta = %s,
		@Sensor = %s,
		@Molinete = '%s'

SELECT	'Return Value' = @return_value

]], fecha, trj, sensor, Molinete)
sql1 = string.format(
[[
EXEC [molinetes].[dbo].[dispositivos_GuardarFichada]
		@FechaHora = '%s',
		@Tarjeta = %s,
		@Sensor = %s,
		@Molinete = '%s')
]], fecha, trj, sensor, Molinete)

local sql = string.format("SELECT CAST(Id AS VARCHAR(36)) AS Id FROM [dbo].[Tarjetas] WHERE Numero = %s", trj)
print(sql)
cur, serr = dbMol:execute(sql)

if serr then 
	print(serr)
end

local row = cur:fetch ({}, "a")
trjId = row.Id
cur:close()
sql = string.format(
[[
		SELECT CAST(Ciudadano AS VARCHAR(36)) AS CiudId
		FROM [dbo].[Personal]
		WHERE Id = (
			select
				Personal
			from [dbo].[TarjetasTemporales]
			where Baja is null
			and Tarjeta = CONVERT(UNIQUEIDENTIFIER,'%s')
			and Alta = (
			  select Max(Alta)
			  from [dbo].[TarjetasTemporales]
			  where Tarjeta = CONVERT(UNIQUEIDENTIFIER,'%s')
--			  and Alta <= CONVERT(DATETIME, '%s', 102)
			)
		)
]], trjId, trjId, fecha)

cur, serr = dbMol:execute(sql)
if serr then 
	print(serr) 
end

row = cur:fetch ({}, "a")

if row then
	ciudId = row.Ciudadano
else
	sql = string.format([[
SELECT TOP 1 CAST(Ciudadano AS VARCHAR(36)) AS CiudId FROM 
	(SELECT Ciudadano FROM Personal WHERE Tarjeta = CONVERT(UNIQUEIDENTIFIER,'%s')
	UNION 
	SELECT Ciudadano FROM Visitantes WHERE Id IN 
		(SELECT Visitante FROM Visitantes_Tarjetas WHERE Tarjeta = CONVERT(UNIQUEIDENTIFIER,'%s') AND Baja is null)
	) AS Ciudadano
]], trjId, trjId)
	print(sql)
	cur, serr = dbMol:execute(sql)
	if serr then print(serr) end 
	row = cur:fetch ({}, "a")
	ciudId = row.CiudId
end
print (trjId, ciudId)