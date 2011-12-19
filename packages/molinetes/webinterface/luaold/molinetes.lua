socket = require("socket")
function connectSocket(host, port)
	local cli
	if cli then 
		cli:close()
		cli = nil
	end
	cli, skerror = socket.connect(host, port)
	if not cli then 
		print("Error no se conecto a "..host.." "..port)
	else
--		cli:settimeout(1,"t")
		srvlen, serror = cli:send("monitor\n")
		print("Abre conexion con "..host.." en puerto:"..port)
		print("cli:send('controler')",srvlen, serror)
	end
	return cli
end

local host = "172.17.0.56"
local port = "8282"
local cli = connectSocket(host, port)

lee = cli:receive()
print (lee)