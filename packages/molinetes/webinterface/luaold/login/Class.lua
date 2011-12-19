require ("iw.db.Class")
loginClass = {}
loginClass_mt = {__index = loginClass} 

function loginClass.new(varName)
	self = {}
	local varName = varName or "VISITOR"
	self.Db = dbClass.new("ast_admin","webserver","sololocal","mysql","localhost")
	self.session = dbTable.new("session",self.Db)
	self.users = dbTable.new("users",self.Db)
	self.varName = varName or "VISITOR"
	self.sessionDb.limit = false;
	self.authenticated = false;
	self:setSessionVarName(varName)
	if self.sessionID then
		self:checkSession()
	end
	setmetatable(self,loginClass_mt)
	return self 
end

function loginClass:setSessionVarName(varName)
	local varName = varName or self.varName
	for str in string.gmatch(__ENV.HTTP_COOKIE, "[^;]%S*") do
		local _, _, k, v = string.find(str, "(%a+)%s*=%s*(.+)")
		if k == varName then
			self.sessionID = v
			break
		end
	end
end

function loginClass:checkSession()
	self.sessionDb:execute("select * from session where idtrack='"..self.sessionID.."'")
	-- Leer del sql la session --
	self.authenticated = false;
	return self.authenticated
end

function loginClass:state(name,val)
	if val == nil then val = "" end
	if self[name]==nil or name == "-" then
		self[#self+1] = {}
		self[#self]["name"] = name
		self[#self]["value"]= val
		self[name]=self[#self]
		self.len = self.len + 1
	else
		self[name].value = val
	end
end

function loginClass:text()
	local str = ""
	for k, v in pairs(self.users:readPage()) do
		str = string.format("%s\n%s=%s<br>",str,k,v)
	end
	str = str.."<br>-----------------------------<br>"
--[[
	for k, v in pairs(getenv("pepe")) do
		str = string.format("%s\n%s=%s<br>",str,k,v)
	end
]]	
	return str
end

