-----------------------------------------------------------------------------
-- Select sample: simple text line server
-- LuaSocket sample files.
-- Author: Diego Nehab
-- RCS ID: $Id: tinyirc.lua,v 1.14 2005/11/22 08:33:29 diego Exp $
-----------------------------------------------------------------------------
local socket = require("socket")
local json = require("json")
require("db.Class")
local dbCon = dbClass.new("molinetes","root", "pirulo","mysql", "172.17.0.56")

require("luasql.mysql")
myenv = assert (luasql["mysql"]())

DEBUG = true

host = host or "*"
--port1 = port1 or 8282
port2 = port2 or 8181
if arg then
    host = arg[1] or host
    port1 = arg[2] or port1
    port2 = arg[3] or port2
end

--server1 = assert(socket.bind(host, port1))
server2 = assert(socket.bind(host, port2))
--server1:settimeout(1) -- make sure we don't block in accept
server2:settimeout(1)

io.write("Servers bound\n")

-- simple set implementationroo
-- the select function doesn't care about what is passed to it as long as
-- it behaves like a table
-- creates a new set data structure
function newset()
    local reverse = {}
    local set = {}
	local object = {}
	
    return setmetatable(set, {__index = {
        insert = function(set, value)
            if not reverse[value] then
                table.insert(set, value)
				table.insert(object, {})
                reverse[value] = table.getn(set)
            end
        end,
		setObject = function(set, value, data)
			object[reverse[value]] = data
		end,
		getObject = function(set, value)
			return object[reverse[value]]
		end,
        remove = function(set, value)
            local index = reverse[value]
            if index then
                reverse[value] = nil
				local otop = table.remove(object)
                local top = table.remove(set)
                if top ~= value then
                    reverse[top] = index
                    set[index] = top
					object[index] = otop
                end
            end
        end
    }})
end

function webClients (msg)
	print("To WebClients")
    local __, writeable, error = socket.select(nil, set, 1)
    for _, output in ipairs(writeable) do
		obj = set:getObject(output)
		if obj.object == "webclient" then
			print("MSG: "..msg.event, "Waiting: "..obj.event)
			if obj.event == msg.event then
				output:send(json.encode(msg).."\n")
			end
		end
	end
end

function process(skt, msg)
	if DEBUG then
--		print("Procesa "..msg)
	end
	msg = json.decode(msg)
	if msg.type == "read" then
		local searchTrj = string.format([[SELECT * FROM `molinetes`.`trj_mov` where tarjeta='%s' ORDER By idtrj_mov DESC LIMIT 1]],msg.tarjeta)
		local cur, serr = dbCon:execute(searchTrj)
		if serr then 
			msg.type="Error"
			msg.data = serr.." - ".. searchTrj
			skt:send(json.encode(msg).."\n")
			return
		end
		if cur:numrows() == 1 then
			row = cur:fetch ({}, "a")
			if row.tipo == "ASIGNA" then
				msg.asignada=row.fecha
				msg.persona=row.a
				cur:close()
				local searchPrs = string.format([[SELECT * FROM `molinetes`.`personas` WHERE id='%s']],msg.persona)
				cur, serr = dbCon:execute(searchPrs)
				if serr then
					msg.type = "Error"
					msg.data = serr.." - ".. searchPrs
					skt:send(json.encode(msg).."\n")
					return
				end
				row = cur:fetch ({}, "a")
				local prsname = row.apellidos.." "..row.nombres
				msg.name = string.sub(prsname.."                ",1,16)
				msg.valid = true
			else
				msg.name = "Tarjeta Invalida "
				msg.valid = false
			end
		else
			msg.name = "Tarjeta Ivalida "
			msg.valid = false
		end
		print("Responde "..json.encode(msg))
		webClients(msg)
		skt:send(json.encode(msg).."\n")
	elseif msg.type == "pasa" then
		if DEBUG then
			print("Gaba ")
			for k,v in pairs(msg) do
				print("",k,v)
			end
			webClients(msg)
		end
	elseif msg.type == "setObject" then
		print("Set Object "..msg.object)
		msg.type = nil
		set:setObject(skt,msg)
	elseif msg.type == "molinfo" then
		webClients(msg)
	else
		webClients(msg)
		
	end
end


set = newset()
webset = newset()

io.write("Inserting servers in set\n")
--set:insert(server1)
set:insert(server2)

while 1 do
    local readable, _, error = socket.select(set, nil)
    for _, input in ipairs(readable) do
        -- is it a server socket?
        if input == server1 then
            io.write("Waiting for clients\n")
            local new = input:accept()
            if new then
                new:settimeout(1)
                webset:insert(new)
            end
        -- it is a client socket
		elseif input == server2 then
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
                io.write("Removing client from set\n")
                set:remove(input)
            else
				process(input, msg)
			end
        end
    end
end
