tabla="oficinas"
sql = string.format([[
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[%s]') AND type in (N'U'))
DROP TABLE [dbo].[%s]
]], tabla,tabla)
doSql(dbnew, sql)

sql = [[
CREATE TABLE [dbo].[tpdoc](
	[id] [smallint] IDENTITY(1,1) NOT NULL,
	[oldId] [uniqueidentifier] NULL,
	[ts] [timestamp] NULL,
	[name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[code] [varchar](4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
 CONSTRAINT [PK_tpdoc] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
]]
doSql(dbnew, sql)
-- Crea indice oldId
sql = string.format([[
CREATE NONCLUSTERED INDEX [oldId] ON [dbo].[%s] 
(
	[oldId] ASC
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]
]], tabla)
doSql(dbnew, sql)

sql = [[
INSERT INTO [newmol].[dbo].[tpdoc]
           (
			[oldId]
           ,[name]
           ,[code]
		   )
     SELECT [Id]
      ,[Descripcion]
      ,[Descripcion]
  FROM [molinetes].[dbo].[TiposDocumento]
]]
doSql(dbnew, sql)

