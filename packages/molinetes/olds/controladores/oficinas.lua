tabla="oficinas"
sql = string.format([[
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[%s]') AND type in (N'U'))
DROP TABLE [dbo].[%s]
]], tabla,tabla)
doSql(dbnew, sql)


sql = [[
CREATE TABLE [dbo].[oficinas](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[oldId] [uniqueidentifier] NOT NULL,
	[ts] [timestamp] NULL,
	[Descripcion] [varchar](500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Organismo] [uniqueidentifier] NOT NULL,
	[Codigo] [int] NOT NULL CONSTRAINT [DF_Oficinas_Codigo]  DEFAULT ((0)),
 CONSTRAINT [PK_OFICINA] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
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
-- Traspasa los datos
sql = string.format([[
INSERT INTO [newmol].[dbo].[%s]
	(
		[oldId],
		[Descripcion],
		[Organismo],
		[Codigo]
	)
	SELECT [Id],
		[Descripcion],
		[Organismo],
		[Codigo]
	FROM [molinetes].[dbo].[%s]
]], tabla, tabla)
doSql(dbnew, sql)

-- Crea los disparadores 
sql = string.format([[
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tr_%s_insert]') AND type in (N'TR'))
	DROP TRIGGER [tr_%s_insert];
]], tabla, tabla)
doSql(dbold, sql)

sql = string.format([[
CREATE TRIGGER tr_%s_insert ON [molinetes].[dbo].[%s]
AFTER INSERT
AS
SET NOCOUNT ON
BEGIN
	INSERT INTO [newmol].[dbo].[%s]
           (
			[oldId]
           ,[Descripcion]
           ,[Organismo]
           ,[Codigo]
		   )
     SELECT * FROM INSERTED
END
]], tabla, tabla, tabla)
doSql(dbold, sql)

sql = string.format([[
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tr_%s_update]') AND type in (N'TR'))
	DROP TRIGGER [tr_%s_update];
]], tabla, tabla)
doSql(dbold, sql)

sql = string.format([[
CREATE TRIGGER tr_%s_update ON [molinetes].[dbo].[%s]
AFTER UPDATE
AS
SET NOCOUNT ON
BEGIN
	UPDATE [newmol].[dbo].[%s] 
		SET
		Descripcion=inserted.[Descripcion],
		Organismo=inserted.[Organismo],
		Codigo=inserted.[Codigo]
		FROM [newmol].[dbo].[%s], inserted
		WHERE [newmol].[dbo].[%s].oldId=inserted.Id
END
]], tabla, tabla, tabla, tabla, tabla)
doSql(dbold, sql)
