require("luasql.mysql")
mySql = assert (luasql["mysql"]())
socket = require("socket")
json = require("json")

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
				print("inserting client")
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
			print("removing client")
        end
    }})
end

function process(skt, msg)
	if DEBUG then
		print("Procesa "..msg)
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
			print("Graba ")
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
		
	end
end


DEBUG = true

host = host or "*"
port = port or 8181
if arg then
    host = arg[1] or host
    port = arg[2] or port
end

set = newset()

server = assert(socket.bind(host, port))
server:settimeout(1)
set:insert(server)

while 1 do
    local readable, _, error = socket.select(set, nil)
    for _, input in ipairs(readable) do
        -- is it a server socket?
        if input == server then
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
