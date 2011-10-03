socket = require("socket")
json = require("json")

function connectSocket(host, port)
	local cli
	cli, skerror = socket.connect(host, port)
	if not cli then 
		print(skerror)
		os.exit(0)
	end
	return cli
end

function setInfo()
	local t = {}
	t.name = "mySMSgateWay"
	t.modems = {}
	t.modems["/dev/ttyUSB0"] = {}
	t.modems["/dev/ttyUSB0"].signal = "20%"
	t.modems["/dev/ttyUSB0"].marca = "SIMENS"
	t.modems["/dev/ttyUSB0"].modelo = "MF10"
	t.modems["/dev/ttyUSB0"].enabled = false
	t.modems["/dev/ttyUSB0"].number = "+543722380337"
	t.modems["/dev/ttyUSB4"] = {}
	t.modems["/dev/ttyUSB4"].signal = "24%"
	t.modems["/dev/ttyUSB4"].marca = "ZTE"
	t.modems["/dev/ttyUSB4"].modelo = "Modem"
	t.modems["/dev/ttyUSB4"].enabled = false
	t.modems["/dev/ttyUSB4"].number = "+543722480337"
	return t
end

function process(cli, msg)
	cmd = json.decode(msg)
	print(cmd.action)
	if cmd.action == "getInfo" then
		msg = {}
		msg.action = "setInfo"
		msg.data = setInfo()
		cli:send(json.encode(msg).."\n")
	end
end

cli = connectSocket("127.0.0.1", "9999")
cli:settimeout(1)

t = {}
t.action = "setObject"
t.data = "smsGateWay"
cli:send(json.encode(t).."\n")

--while true do
	msg = cli:receive()
	if msg then 
		process(cli,msg)
	end
--	t = {}
--	t.action = "showInfo"
--	cli:send(json.encode(t).."\n")
--	cli:send(json.encode("algo").."\n")
	io.read()
--end
t = {}
t.action = "setInfo"
t.data = setInfo()
t = {}
t.action = "showType"

cli:send(json.encode(t).."\n")


