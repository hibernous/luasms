require("smspdu")
local dbCon = openDB()
local modems = {}

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
	t.object = "gateway"
	t.event = "entrasale"
	cli:send(json.encode(t).."\n")
	return cli
end

local host = "localhost"
local port = "8181"
local cli = connectSocket(host, port)




ldevs = {
	{ port = "/dev/ttyUSB0", number = "+543722380337" },
	{ port = "/dev/ttyUSB4", number = "+543722438710" }
}

local modems = setModem(ldevs,"matrix")
local gateway = "matrix"
while true do
for m, com in pairs(modems) do
	if com.dev == nil then
		com.dev , info = openPort(m)
	else
		_, com.signalLevel, status	= command(com.dev,"+CSQ") 		--Signal level
		slevel = com.signalLevel:gsub("%+CSQ: (%d+),%d+", "%1")
		slevel = tonumber(slevel)
		if slevel == nil then 
			slevel = 0
			com.dev:close()
			com.dev = nil
		end
		if status ~= "OK" or slevel < 11 then 
			com.enabled = false
		else
			com.enabled = true
		end
		print(m)
		print("Puerto        ", m)
		print("Marca         ", com.marca)
		print("Modelo        ", com.modelo)
		print("Nro Serie     ", com.serialNumber)
		print("Operador      ", com.operator)
		print("Numero        ", com.number)
		print("IMS Identity  ", com.IMSIdentity)
		print("SMS Gateway   ", com.smsGateWay)
		print("Nivel de Señal", string.format("%2d%%",slevel))
		print("Enabled       ", com.enabled)
		trspta = pdu_getList(com.dev)
	
		for i, t in ipairs(trspta) do
			print(t.mem, t.idx, t.status, t.sender, t.fecha, t.concat, t.part_id, t.part_idx, t.parts, "\n"..t.msg)
			saveMsg(t,com,dbCon)
		end
		
		sql = string.format("SELECT * FROM envia WHERE sendtime IS NULL")
		cur, serr = doSQL(dbCon, sql)
		if cur then
			row = cur:fetch({},"*a")
			while row do
				rspta, text, status = sendMessage(com.dev, row.tonumber, row.msg)
				print(status)
				if status == "OK" then
					sql = string.format("UPDATE envia SET sendtime='%s', gateway='%s', fromnumber='%s' WHERE idenvia='%s'"
					, os.date("%x %X")
					, gateway
					, com.number
					, row.idenvia)
					doSQL(dbCon,sql)
				else
					print(status)
				end
				row = cur:fetch({},"*a")
			end
		end
		socket.sleep(1)
	end
end
end
dev:close()