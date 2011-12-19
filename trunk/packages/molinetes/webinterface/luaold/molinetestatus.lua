socket = require("socket")
json = require("json")

function retData(strData)
	io.write("Contetnt-Type: text/xml; charset=UTF-8\r\n")
	io.write("Status: 200\r\n")
	io.write("\r\n")
	io.write(strData)
	io.write("\r\n")
end

function connectSocket(host, port)
	local cli
	cli, skerror = socket.connect(host, port)
	if not cli then 
		t = {}
		t.type = "Error"
		t.msg = skerror
		retData(json.encode(t))
		os.exit(0)
	end
	t = {}
	t.type = "setObject"
	t.object = "webclient"
	t.event = "molinetestatus"
	cli:send(json.encode(t).."\n")
	return cli
end

local host = "172.17.0.56"
local port = "8181"
local cli = connectSocket(host, port)

local lee = cli:receive()
local reg = json.decode(lee)
lee=json.encode(reg)
--cur:close()
retData(lee)
os.exit(0)
