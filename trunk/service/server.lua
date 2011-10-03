require ("common")

set = newset()
set:insert(serverObject:new("*","9999"))
set:loop()
--[[
while 1 do
    local readable, _, error = socket.select(set, nil)
    for _, input in ipairs(readable) do
		print("INPUT", input)
		print("")
		obj = set:getObject(input)
        if obj.obType == "server" then
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
				obj:process( msg)
			end
        end
    end
end
]]
