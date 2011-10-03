socket = require("socket")
json = require("json")

serverObject = {type="Server"}
function  serverObject:new(host, port)
	local ob = {}
	ob.port = port or "9999"
	ob.host = host or "*"
	ob.type = "Server"
	ob.socket = assert(socket.bind(host, port))
	setmetatable(ob, self)
	self.__index = self
	return ob
end

clientObject = {}
function clientObject:new(skt)
	local obj = {}
	obj.type = "Client"
	obj.socket = skt
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function clientObject:setInfo(data)
	self.info = data or {}
	self.info.host = self.socket:getpeername()
end	

function clientObject:showType(data)
	print(self.type)
end	

smsGateWay = clientObject:new{socket=skt}
function smsGateWay:new(skt)
	local obj = {}
	obj.type = "smsGateWay"
	obj.socket = skt
	setmetatable(obj, self)
	self.__index = self
	t = {}
	t.action = "getInfo"
	skt:send(json.encode(t).."\n")
	return obj
end

function smsGateWay:setItemInfo(data)
	print("Hay que pensar como")
	
end

function setObject(skt,data)
	local obj = {}
	print("setObject", data)
	if data == nil then
		obj = clientObject:new(skt)
	elseif data == "smsGateWay" then
		print("entro al seteo de objeto")
		obj = smsGateWay:new(skt)
		print(obj.type)
	else
		obj = clientObject:new(obj.socket)
	end
	return obj
end
		
function newset()
    local reverse = {}
    local set = {}
	local object = {}
    return setmetatable(set, {__index = {
        insert = function(set, value)
			if value.socket then
				if not reverse[value.socket] then
					table.insert(set, value.socket)
					object[value.socket] = value
					reverse[value.socket] = table.getn(set)
					print("Inserting "..value.type)
				end
			else
				table.insert(set, value)
				object[value] = setObject(value)
				reverse[value] = table.getn(set)
				print("Inserting Client ",value)
			end
        end,
		getObject = function(set, value)
			return object[value]
		end,
        remove = function(set, value)
            local index = reverse[value]
            if index then
				print("removing "..(object[value].type or ""))
                reverse[value] = nil
				object[value] = nil
                local top = table.remove(set)
                if top ~= value.socket then
                    reverse[top] = index
                    set[index] = top
                end
            end
        end,
		loop = function (set)
			while true do
			    local readable, _, error = socket.select(set, nil)
    			for _, input in ipairs(readable) do
					obj = set:getObject(input)
			        if obj.type == "Server" then
            			local new = input:accept()
            			if new then
            			    new:settimeout(1)
            			    set:insert(new)
						end
        			else
        		    	local msg, error = input:receive()
        		    	if error then
							io.write(string.format("Error: %s\n",error))
        		    	    input:close()
        		    	    set:remove(input)
        		    	else
							cmd = json.decode(msg)
							if cmd.action == "setObject" then
								object[input] = nil
								object[input] = setObject(input,cmd.data)
							else
								if type(obj[cmd.action]) == "function" then
									obj[cmd.action](obj, cmd.data)
								else
									print ("Método no definido")
									print(msg)
--									obj = obj:process(cmd)
								end
							end
						end
        			end
    			end
			end
		end
    }})
end

