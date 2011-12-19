require "luasql.odbc"
mssql = luasql.odbc()
require "luasql.mysql"
mysql = luasql.mysql()

function openMy()
	local host = "172.17.0.56"
	local connMy, serr = mysql:connect("dbo_molinetes","root", "pirulo", host)
	if not connMy then
		print("Error al conectar con MySql en Host: "..host)
		os.exit(1)
	end
	return connMy
end

function openMS(data)
--	local dataSource = "moli"	-- 10.10.8.6
	local dataSource = data	-- 172.17.0.18
	local connMS = mssql:connect(dataSource) 
	if not connMS then
		print("Error al conectar MS-SQL con DataSource '"..dataSource)
		os.exit(1)
	end
	return connMS
end

function addslashes(s)
	local s = s or ""
	s = string.gsub(s, "(['\"\\])", "\\%1")
	return (string.gsub(s, "%z", "\\0"))
end

function doSql(dbCon,str)
--	print(str)
	local rslt, serr = dbCon:execute(sql)
	if serr then
		print(serr)
		os.exit(0)
	end
end

function doTra(dbCon,str)
--	print(str)
	local rslt, serr = dbCon:execute(sql)
end

function getCur(dbCon, sql)
	local cur, serr = dbCon:execute(sql)
	if serr then 
		print(serr) 
		os.exit(0)
	end
	return cur
end

function createTable(str)
	sql = string.format([[
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tr_%s_insert]') AND type in (N'TR'))
DROP TRIGGER [tr_%s_insert];
]], str, str)
	doSql(dbtr, sql)

end

dbnew = openMS("newmoli")
dbold = openMS("moli")
dbtr = openMS("moli")
dbnov = openMS("novedades")


local cur = getCur(dbold,[[
SELECT 
	CAST(TABLE_NAME AS VARCHAR(256)) TABLE_NAME, 
	CAST(COLUMN_NAME AS VARCHAR(256)) COLUMN_NAME 
FROM information_schema.columns
]])
local row = cur:fetch ({}, "a")
while row do
	if row.COLUMN_NAME == "Id" then
		print("Procesando "..row.TABLE_NAME)
		createTable(row.TABLE_NAME)
	end
	row = cur:fetch ({}, "a")
end

