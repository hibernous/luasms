--socket = require ("socket")
-- Para el acceso al MS-SQL
require "luasql.odbc"
mssql = luasql.odbc()
-- Para el acceso al MySql
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
	print(str)
	local rslt, serr = dbCon:execute(sql)
	if serr then
		print(serr)
		os.exit(0)
	end
end

function getCur(dbCon, sql)
	local cur, serr = dbCon:execute(sql)
	if serr then 
		print(serr) 
		os.exit(0)
	end
	return cur
end

dbnew = openMS("newmoli")
dbold = openMS("moli")
sql = "DROP DATABASE newMol"
sql = "CREATE DATABASE newMol"

require ("organismos")
require ("oficinas")

sql = [[
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ciudadanos]') AND type in (N'U'))
DROP TABLE [dbo].[ciudadanos]
]]
doSql(dbnew, sql)
sql = [[
CREATE TABLE [dbo].[ciudadanos](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[oldId] [uniqueidentifier] NULL,
	[ts] [timestamp] NULL,
	[apellidos] [varchar](50) COLLATE Modern_Spanish_CI_AS NULL,
	[nombres] [varchar](50) COLLATE Modern_Spanish_CI_AS NULL,
	[nacio] [datetime] NULL,
	[sexo] [nchar](1) COLLATE Modern_Spanish_CI_AS NULL,
	[tpdoc] [smallint] NULL,
	[nrdoc] [varchar](50) COLLATE Modern_Spanish_CI_AS NULL,
	[idoperador] [bigint] NULL,
 CONSTRAINT [PK_ciudadanos] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
]]

doSql(dbnew, sql)
sql = [[
	INSERT INTO [newmol].[dbo].[ciudadanos]
			([oldId]
			,[apellidos]
		   ,[nombres]
           ,[tpdoc]
           ,[nrdoc])
		SELECT Id,
			Apellido, 
			Nombre,
			(SELECT [newmol].[dbo].[tpdoc].id FROM [newmol].[dbo].[tpdoc] WHERE [newmol].[dbo].[tpdoc].[code]=(SELECT Descripcion FROM [molinetes].[dbo].[TiposDocumento] WHERE [molinetes].[dbo].[TiposDocumento].Id=[molinetes].[dbo].[Ciudadanos].TipoDocumento)) AS tpdoc,
		NumeroDocumento
		FROM [molinetes].[dbo].[Ciudadanos]
]]
doSql(dbnew, sql)
--[[
while row do
	print(row.oldId, row.Apellido, row.Nombre, row.tpdoc, row.NumeroDocumento)
	row = cur:fetch ({}, "a")
end
]]