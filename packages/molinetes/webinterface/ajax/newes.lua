socket = require("socket")
require("lua.ajaxresponse")
function connectSocket(host, port)
	local cli
	cli, skerror = socket.connect(host, port)
	if not cli then 
		t = {}
		t.type = "Error"
		t.msg = skerror
		cli:send(json.encode(t).."\n")
		os.exit(0)
	end
	t = {}
	t.type = "setObject"
	t.object = "webclient"
	t.event = "EntradaSalida"
	cli:send(json.encode(t).."\n")
	return cli
end

local host = "172.17.0.56"
local port = "8181"
local cli = connectSocket(host, port)

data = cli:receive()
ajax_responce(data)
