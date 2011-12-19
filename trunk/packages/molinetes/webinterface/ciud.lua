require "luasql.odbc"
mssql = luasql.odbc()
connMS = mssql:connect("moli1","sa","vamosGlobant") 

require "luasql.mysql"
mysql = luasql.mysql()
connMy, serr = mysql:connect("dbo_molinetes","root", "pirulo","172.17.0.56")

function addslashes(s)
  if s == nil then return s end
  s = string.gsub(s, "(['\"\\])", "\\%1")
  return (string.gsub(s, "%z", "\\0"))
end

function trim (str)
	if str == nil then return "" end
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

function fixNames(str)
	if str == nil then return "" end
	local str = str:lower()
	t = {}
	for name in string.gmatch(str,"%S+") do
		t[#t+1]= name:gsub("%a", string.upper, 1)
	end
	str = ""
	for i=1, #t do
		str = str..t[i].." "
	end
	str = trim(str)
	str = addslashes(str)
	return str
end

function trans_TiposDocumentos()
	local tpdoc = {}
--	dropTable("tpdoc")
	print("Transfiriendo Tipos de Documentos")
	local cur, serror = connMy:execute("SELECT * FROM TiposDocumento")
	if cur then
		local row = cur:fetch ({}, "a")
		while row do
			tpdoc[row.Id] = row.Descripcion --TiposDocumento_id
--			sql = string.format("INSERT INTO tpdoc SET id='%s', code='%s', name='%s' ON DUPLICATE KEY UPDATE code='%s'", row.TiposDocumento_id, row.Descripcion, row.Descripcion, row.Descripcion)
--			graba(sql)
			row = cur:fetch ({}, "a")
		end
	else
		print(serror)
	end
	return tpdoc
end


sql = [[
	SELECT Ciudadanos AS Id, Apellido, Nombre, TipoDocumento, NumeroDocumento, Direccion, Telefonos FROM HST_Ciudadanos Group By Ciudadanos
]]

sql = [[
SELECT * FROM (
	SELECT Ciudadanos AS Id, Apellido, Nombre, TipoDocumento, NumeroDocumento, Direccion, Telefonos FROM HST_Ciudadanos GROUP BY Ciudadanos
	UNION
	SELECT Id, Apellido, Nombre, TipoDocumento, NumeroDocumento, Direccion, Telefonos FROM Ciudadanos
) R Group BY Id
]]

sql2 = [[
	SELECT Id, Apellido, Nombre, TipoDocumento, NumeroDocumento, Direccion, Telefonos FROM Ciudadanos
]]

sql = [[
SELECT * FROM (
	SELECT Personal AS Id, Ciudadano, Oficina, Tarjeta, Estado FROM HST_Personal H
		WHERE NOT ISNULL(Tarjeta) 
		  AND Estado!='0CFD4202-6033-4417-86BC-C324D9766462' group by Ciudadano
UNION
	SELECT Id, Ciudadano, Oficina, Tarjeta, Estado FROM Personal P 
		WHERE NOT ISNULL(Tarjeta) 
		  AND Estado!='0CFD4202-6033-4417-86BC-C324D9766462'
) R Group By Id, Ciudadano
]]


cur, serr = connMy:execute(sql)
if serr then
	print(serr)
	os.exit(0)
end
local row = cur:fetch ({}, "a")
local c = 1
rows = {}
while row do 
	rows[#rows+1] = row
	print(c, row.Id, row.Ciudadano, row.Oficina, row.Tarjeta)
	c = c + 1
	row = cur:fetch ({}, "a")
end

cur:close()

sql = [[
SELECT * FROM (
	SELECT 
		Ciudadanos AS Id, 
		Apellido, 
		Nombre, 
		TipoDocumento, 
		NumeroDocumento, 
		Foto,
		Direccion, 
		Telefonos 
	FROM `dbo_molinetes`.`HST_Ciudadanos`
UNION
	SELECT 
		Id, 
		Apellido, 
		Nombre, 
		TipoDocumento, 
		NumeroDocumento,
		Foto,
		Direccion, 
		Telefonos 
	FROM `dbo_molinetes`.`Ciudadanos`
) SUMC GROUP BY Id
]]

	local tpdoc = trans_TiposDocumentos()
	local desde = 1
	local limit = 10000
	local cur, serr = connMy:execute(string.format("%s LIMIT %d, %d",sql,desde,limit))
	if serr then
		print(serr)
		os.exit(0)
	end
	local leyo = cur:numrows()
	while leyo > 0 do
		desde = desde + leyo
		local row = cur:fetch ({}, "a")
		while row do
			local tpd = tpdoc[row.TipoDocumento]
--			local id = row.Ciudadanos_id
			local apellidos = fixNames(row.Apellido)
			local nombres = fixNames(row.Nombre)
			local numero = row.NumeroDocumento
--			local data = addslashes(row.Foto)
			local filename = tpd..row.NumeroDocumento..apellidos:gsub(" ", "")
			local alt = apellidos.." "..nombres

			print(string.format("%s %-3s %-12s %s %s", row.Id, tpd, numero, apellidos, nombres ))
			row = cur:fetch ({}, "a")
		end
		cur:close()
		if leyo == limit
		then
			print("Procesadas : ", desde-1)
		else
			print("Procesadas : ", desde)
			break
		end
		cur, serr = connMy:execute(string.format("%s LIMIT %d, %d",sql,desde,limit))
		leyo = cur:numrows()
	end
