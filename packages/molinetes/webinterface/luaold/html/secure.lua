require("iw.utils.cgi_env")

htmlSecureClass = {}
htmlSecureClass_mt = {__index = htmlSecureClass} 

function htmlSecureClass.new()
	self = {}
	setmetatable(self,loginClass_mt)
	return self 
end

function htmlSecureClass:state(name,val)
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

function htmlSecureClass:text()
	local str = ""
	for k, v in pairs(__ENV) do
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
