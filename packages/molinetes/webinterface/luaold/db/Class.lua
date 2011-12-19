--------------------------------------------------------------------------------
-- dbClass.lua
--
-- Author(s) [in order of work date]:
--       Fabián Omar Franzotti
--
--------------------------------------------------------------------------------
dbClass = {} 
dbClass_mt = {__index = dbClass}

function dbClass.new(dbName,dbUser,dbPass,driver,dbHost,dbPort)
	self = {}
	self.dbName = dbName
	self.dbUser = dbUser
	self.dbPass = dbPass
	self.driver = driver or "mysql"
	self.dbHost = dbHost
	self.dbPort = dbPort
	setmetatable(self,dbClass_mt)
	return self 
end

function dbClass:environ()
	require("luasql."..self.driver)
	self.env = assert (luasql[self.driver]())
	if self.env == nil then
		print("dbEnvironment Error")
	end
end

function dbClass:connect()
	if self.env == nil then 
		self:environ()
	end
	self.con = assert (self.env:connect(self.dbName,self.dbUser,self.dbPass,self.dbHost,self.dbPort))
end

function dbClass:close()
	self:con_close()
	self:env_close()
end

function dbClass:env_close()
	if self.env then
		self.env:close()
		self.env=nil
	end
end

function dbClass:con_close()
	if self.con then
		self.con:close()
		self.con=nil
	end
end

function dbClass:execute(strQry)
	local strQry = strQry or self.strQry
	if self.con == nil then
		self:connect()
	end
	local cur, curError = assert (self.con:execute (strQry))
	return cur, curError
end

--[[
function dbClass:tableOpen(strTable)
	self.table = strTable or self.table
	if self.table then
		self.rows = {}
		self.strQry = "SELECT * FROM %s"..self.table
		self:execute(strQry)
		self.numrows = self.cur:numrows()
		if self.limit ~= false then
			self.pages = self:calcPages(self.numrows, self.limit)
		else
			self.pages = 1
		end
		self.cpage = 1
	end
end
]]

require("db.table")