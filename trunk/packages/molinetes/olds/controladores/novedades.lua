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
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[%s]') AND type in (N'U'))
DROP TABLE [dbo].[%s]
]], str, str)
	doSql(dbnov, sql)

	sql = string.format([[
CREATE TABLE [dbo].[%s](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[oldId] [uniqueidentifier] NOT NULL,
	[ts] [timestamp] NULL,
CONSTRAINT [PK_%s] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
]], str, string.upper(str))
	doSql(dbnov,sql)
	sql = string.format([[
CREATE NONCLUSTERED INDEX [oldId] ON [dbo].[%s] 
(
	[oldId] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]
]], str)
	doSql(dbnov, sql)
-- Traspasa los datos
	sql = string.format([[
INSERT INTO [novedades].[dbo].[%s]
	(
		[oldId]
	)
	SELECT [Id]
	FROM [molinetes].[dbo].[%s]
]], str, str)
doTra(dbnov, sql)

	sql = string.format([[
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tr_%s_insert]') AND type in (N'TR'))
DROP TRIGGER [tr_%s_insert];
]], str, str)
	doSql(dbtr, sql)

	sql = string.format([[
CREATE TRIGGER tr_%s_insert ON [molinetes].[dbo].[%s]
AFTER INSERT
AS
SET NOCOUNT ON
BEGIN
	INSERT INTO [novedades].[dbo].[%s]
           (
			[oldId]
		   )
     SELECT Id FROM INSERTED
END
]], str, str, str)
doSql(dbtr, sql)

sql = string.format([[
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tr_%s_update]') AND type in (N'TR'))
DROP TRIGGER [tr_%s_update];
]], str, str)
doSql(dbtr, sql)

sql = string.format([[
CREATE TRIGGER tr_%s_update ON [molinetes].[dbo].[%s]
AFTER UPDATE
AS
SET NOCOUNT ON
BEGIN
	UPDATE [novedades].[dbo].[%s] 
		SET
		oldId=inserted.[Id]
		FROM [novedades].[dbo].[%s], inserted
		WHERE [novedades].[dbo].[%s].oldId=inserted.Id
END
]], str, str, str, str, str)
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

