socket = require("socket")
json = require("json")
require("smscompress")
require("smsrs232")
require("smsdb")

DEBUG = 2

function printDL(level, ...)
	if level == 0 then return end
	local lista = {...}
	local level = level or 99
	local ttipo = {"ERROR", "ERROR", "WARNING", "INFO"}
	local stipo = "DEBUG-INFO"
	if level < 5 then 
		stipo = ttipo[level]
	end
	if level <= DEBUG then
--		io.write(string.format("%s %s:%s %s ",os.date("%x %X",socket.gettime()), PROGRAM, FUNCTION,stipo))
		if level < 5 then
			io.write(string.format("%s %s",os.date("%x %X", socket.gettime()), stipo))
		else
			io.write("\t")
		end
		if lista then
			for i=1, #lista do
				io.write(" "..tostring(lista[i]))
			end
		end
		io.write("\n")
	end
end
--[[
	SMS Functions
]]
function leer(dev)
	local t1 	= socket.gettime()
	local str		= ""
	local status	= ""
	local serr		= nil
	local text		= ""

	while true do
		local e, rspta = dev:read(1,100)
		if socket.gettime() - t1 > 5 then 
			return {text=str, status="ERROR TimeOut", rawdata=text}, text, status, str, "timeout"
		end
		if rspta==nil then
			if str:match("ERROR: %d+\r\n$") then 
				status = trim(str:match("ERROR: %d+\r\n$"))
				break
			end
			if str:sub(-7) == "ERROR\r\n" then 
				status = trim(str:sub(-7))
				break 
			end
			if str:sub(-4) == "OK\r\n" then
				status = trim(str:sub(-4))
				break 
			end
		else
			t1 = socket.gettime()
			str = str .. rspta
		end
	end
	text = trim(str:gsub(status,""))
	return {text=text, status=status, rawdata=str}, text, status, str, serr
end

function leersend(dev)
	local str = ""
	local serr = nil
	local esta = false
	while true do
		local e, rspta = dev:read(1,100)
		if rspta==nil then 
			if str:sub(-7) == "ERROR\r\n" then break end
			if str:sub(-4) == "OK\r\n" then break end
			if esta == true then break end
		else
			if str:sub(-1) == ">" then esta = true end
--			print(string.byte(rspta),rspta)
			str = str .. rspta
		end
	end
	return str, serr
end

function command(dev,cmd)
	local cmd = cmd or ""
	cmd = string.format("AT%s\r\n",cmd)
--	print(cmd)
	dev:write(cmd)
--	socket.sleep(.5)
	local tmsg, str, serr = leer(dev)
	if DEBUG > 4 then
		print("cmd: "..tostring(cmd),"msg: "..tostring(str),"status: "..tostring(serr))
	end
	return tmsg, str, serr
end

function checkMsgs(dev)
	local rspta, text, status, fullmsg, serr = command(dev,"+CPMS?")				-- Obtiene los valores de las distintas memorias y cantidad de mensajes en cada una
	local tmsgs = {}
	for mem, i, e in string.gfind(rspta.text,'"(%a+)",(%d+),(%d+)') do
		tmsgs[mem] = {cnt=i, of=e}
	end
	return  tmsgs
end


function readAllMessages(modem)
	local dev = modem.dev
	local trspta = {}
	rspta, text, status, str, serr =command(dev,"+CMGF=1") 		-- Setea Modo Texto
	if rspta.status == "OK" then
		local rspta, serr = command(dev,"+CPMS?")				-- Obtiene los valores de las distintas memorias y cantidad de mensajes en cada una
		local tmsgs = {}
		for mem, i, e in string.gfind(rspta.text,'"(%a+)",(%d+),(%d+)',2) do
			tmsgs[mem] = {cnt=i, of=e}
		end
		for k, t in pairs(tmsgs) do					-- Procesa cada Memoria
			if tonumber(t.cnt) > 0 then
				rspta, str, serr = command(dev,string.format('+CPMS="%s"',k))
				rspta, str, serr  = command(dev,'+CMGL="ALL"')
				local j = split(rspta.text, "+CMGL: ")
				for i, line in ipairs(j) do
					local s, e, status = string.find(line,"\r\n\r\n(%w+)")
					if s and e and status then
						line = line:sub(1,s-1)
					end
					for idx, status, callerId, nada, fecha, msg in string.gfind(line, '(%d+),"([^"]*)","([^",]*)",([^,]*),"([^"]*)"\r\n(.+)') do
						trspta[#trspta+1] = {}
						trspta[#trspta].mem = k
						trspta[#trspta].dev = modem.dev
						trspta[#trspta].cmd = "+CMGL: "
						trspta[#trspta].msg = msg or ""
						trspta[#trspta].fecha = fecha or ""
						trspta[#trspta].fecha = "20"..t.fecha:gsub("/","-")
						trspta[#trspta].fecha = t.fecha:gsub(","," ")
						trspta[#trspta].nose = nada or ""
						trspta[#trspta].callerId = callerId or ""
						trspta[#trspta].status = status or ""
						trspta[#trspta].idx = idx or ""
						trspta[#trspta].rawdata = "+CMGL: "..line
					end
--[[
				for idx, status, callerId, nada, msg in string.gfind(line, '(%d+),"([^"]*)","([^",]*)",([^,]*),\r\n(.+)') do
					msg = msg or ""
					fecha = fecha or ""
					nada = nada or ""
					callerId = callerId or ""
					status = status or ""
					idx = idx or ""
					print(string.format("idx:'%s'\n\tst:'%s',\n\ttoNum:'%s',\n\tnada:'%s',\n\tfecha:'%s',\n\tmsg:'%s'",idx, status, callerId, nada, fecha, msg))
				end
]]
				end
			end
		end
	else -- Modo texto no soportado
		print("Modo Texto no Soportado")
	end
	return trspta
end

function readMessage(dev,mem,idx)
	local tmsg = {}
	tmsg, text, status, str, serr =command(dev,"+CMGF=0") 		-- Setea Modo Hexadecimal
	tmsg, text, status, str, serr = command(dev,string.format('+CPMS="%s"',mem)) -- Setea Memoria a leer
	if tmsg.status == "OK" then
		return command(dev,string.format('+CMGR=%s',idx))	-- Lee mensage en la posicion idx
	end
	return nil
end


function sendMessage(dev, nro, msg)
	local str, serr = command(dev,"+CMGF=1")
	str, serr = command(dev,"+CSMS=1")
	str, serr = command(dev,'+CPMS="SM"')
	str, serr = command(dev,"+CMGF=1")
	str, serr = command(dev,'+CSCS="GSM"')
	str, serr = command(dev,'+CMEE=1')
	local tosend = string.format('AT+CMGS="%s",129\r',nro)
--	local tosend = string.format('AT+CMGS="%s"\r\n',nro)
	print("------------------------------------------")
	print(tosend)
	print("------------------------------------------")
	dev:write(tosend)
	rspta = leersend(dev)
	print("R Msg2", rspta)
	msg=msg:sub(1,110)
	tosend = string.format('%s%s',msg,string.char(26))
	print("------------------------------------------")
	print(tosend)
	print("------------------------------------------")
	dev:write(tosend)
	rspta = leer(dev)
	print("R Msg2", rspta)

end

function proccess(dev)
	if dev then
		local msgs;
		local tmsg, rspta , serr = command(devs[a],"")
--		if rspta and rspta:match("OK") then
		if tmsg.status == "OK" then
			tmsg = command(devs[a],"+CPIN?")
			if tmsg.status == "OK" then
				print("/dev/ttyUSB"..a)
				tmsgs = readMessages(devs[a])
			else
				print("/dev/ttyUSB"..a)
				print(tmsg.text, tmsg.status)
			end
		end
		if msgs then
		if #msgs > 0 then
			for i, t in ipairs(msgs) do
				print(t.fecha,t.callerId,t.msg)
				print("")
				if t.status=="REC UNREAD" then
--				if #msgs == i then
--					sendMessage(devs[a],t.callerId,"Mensaje SMS Recibido: "..t.msg)
				end
			end
		end
		end
	else
		print(info)
	end
end

function checkModem(ldevs)
	devs = {}
	modem = {}
	IMSI = {}
	for _, a in ipairs(ldevs) do
		print("Abriendo port "..a)
		local topen = socket.gettime()
		dev , info = openPort(a)
		print(info)
		if dev then
			topen = socket.gettime() - topen
			local tmsg = command(dev,"")
			if tmsg.status == "OK" then
				IMSIdentity 			= command(dev,'+CIMI')		-- InternationalMobileSubscriberIdentity
				modem[a] = {}
				modem[a].timeopen 		= topen
				modem[a].IMSIdentity	= IMSIdentity
				modem[a].smsGateWay		= command(dev,"+CSCA?") 	-- obtiene el gateway y el modo 
				modem[a].operator		= command(dev,"+COPS?") 	-- Nombre del proveedor
				modem[a].dev			= dev						-- handle port
				modem[a].marca 			= command(dev,'+CGMI')		-- Marca
				modem[a].modelo			= command(dev,'+CGMM')		-- Modelo
				modem[a].revision 		= command(dev,'+CGMR')		-- Revision
				modem[a].serialNumber	= command(dev,'+CGSN')		-- Serial Number
				modem[a].signalLevel	= command(dev,"+CSQ") 		--Signal level
				modem[a].enabled		= true
				if modem[a].IMSIdentity.status == "OK" then
					if IMSI[IMSIdentity.text] then
						print(IMSIdentity.text,modem[IMSI[IMSIdentity.text]].timeopen,topen)
						if 	modem[IMSI[IMSIdentity.text]].timeopen > topen then 
							modem[IMSI[IMSIdentity.text]].dev:close()
							modem[IMSI[IMSIdentity.text]] = nil
							IMSI[IMSIdentity.text] = a
						else
							modem[a].dev:close()
							modem[a] = nil
						end
					else
						IMSI[IMSIdentity.text] = a
					end
				else
					print(a.." No tiene SIM o SIM no funciona")
					modem[a].enabled		= false
					modem[a].dev:close()
					modem[a].dev = nil
				end
			else
				print(a.." no es modem")
				dev:close()
			end
		end
	end
	return modem
end

function findModem()
	ldevs = {}
	fdevs = io.popen("ls /dev/ttyUSB*")
	for line in fdevs:lines() do
		ldevs[#ldevs+1]=line
	end
	fdevs:close()
	fdevs = io.popen("ls /dev/ttyS*")
	for line in fdevs:lines() do
		ldevs[#ldevs+1]=line
	end
	fdevs:close()
	return checkModem(ldevs)
end

function isVoto(t,dbCon)
	local _, _, mesa, votos, fpv_presi, fpv_sena, fpv_dip, b_presi, b_sena, b_dip = t.msg:gmatch("(%d+)%.(%d+)%.(%d+)%.(%d+)%.(%d+)%.(%d+)%.(%d+)%.(%d+)")
	if mesa then
		print(mesa, votos, fpv_presi, fpv_sena, fpv_dip, b_presi, b_sena, b_dip)
		return 1
	end
	return 0
end

function showRspta(t,dbCon)
	print(k, t)
--		print (t.fecha, t.callerId, t.msg)
end

function decompress(str)
	local hc = 0
	local comp = ""
	str = string.gsub(str, "(%x%x)", function (h)
		hc 				= hc + 1
		local bin 		= hex2bin(h)
		local subin 	= bin:sub(hc+1)
		local toconv 	= "0"..subin..comp
		local rslt 		= string.char(bin2dec(toconv:sub(1,8)))
--		print(rslt, h, hc, bin, subin, comp, toconv)
		comp 			= bin:sub(1,hc)
		if hc == 8 then
			hc = 0
			comp = ""
		end
		return rslt
	end)
	
	return str
end


function decompress1(str)
	local hc = 0
	local comp = ""
--	print("Resto",str:len() % 16)
	if (str:len() % 16) > 0 then
		str = str.."00"
	end
	str = string.gsub(str, "(%x%x)", function (h)
		hc 				= hc + 1
		local bin 		= hex2bin(h)
		local subin		= bin:sub(hc+1)
		local toconv	= "0"..subin..comp
		local rslt 		= string.char(bin2dec(toconv:sub(1,8)))
--		print(rslt, h, hc, bin, subin, comp, toconv)
		comp 			= bin:sub(1,hc)
		if hc == 8 then
			hc		= 1
			comp	= ""
			bin		= hex2bin(h)
			subin	= bin:sub(hc+1)
			toconv	= "0"..subin..comp
			rslt	= rslt .. string.char(bin2dec(toconv:sub(1,8)))
			comp	= bin:sub(1,hc)
		end
		return rslt
	end)
	
	return str
end

function getReg(str,len)
	return str:sub(1,len), str:sub(len+1)
end
