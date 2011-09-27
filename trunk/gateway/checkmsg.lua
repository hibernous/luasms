require("smscommon")
port = arg[1]
DEBUG = 2

--function readMessages(modem)
function text_getList(dev)
	local trspta = {}
	local rspta, text, status, fullstr, serr =command(dev,"+CMGF=1") 		-- Setea Modo Texto
	if rspta.status == "OK" then
		local tmsgs = checkMsgs(dev)
		for k, t in pairs(tmsgs) do					-- Procesa cada Memoria
			if tonumber(t.cnt) > 0 then
				rspta, text, status, fullstr, serr = command(dev,'+CMGL="ALL"')
--				print(escape(text))
				local j = split(rspta.text, "+CMGL: ")
				for i, line in ipairs(j) do
	--				print("------------------------------")
					print(i,escape(line))
					local s, e, status = string.find(line,"\r\n\r\n(%w+)")
--					print("Find Status =",s,e,status)
					if s and e and status then
						line = line:sub(1,s-1)
					end
--					print("------------------------------")
--					print("////////////////////////////////////")
					for idx, status, callerId, idbook, fecha, msg in string.gfind(line, '(%d+),"([^"]*)","([^",]*)",([^,]*),"([^"]*)"\r\n(.+)') do
						_, _, udh_bytes, udh_bytes, udh_bytes_follows, udh_id, udhline, udh_parts, udh_idx = msg:find("(.)(.)(.)(.)(.)(.)(.)")
						print(string.byte(udh_bytes), string.byte(udh_bytes), string.byte(udh_bytes_follows), string.byte(udh_id), string.byte(udhline), string.byte(udh_parts), udh_idx)
						print(udh_bytes, udh_bytes, udh_bytes_follows, udh_id, udhline, udh_parts, udh_idx)
						trspta[#trspta+1] = {}
						trspta[#trspta].mem = k
						trspta[#trspta].dev = dev
						trspta[#trspta].cmd = "+CMGL: "
						trspta[#trspta].msg = escape(msg) or ""
						trspta[#trspta].fecha = fecha or ""
						trspta[#trspta].idbook = idbook or ""
						trspta[#trspta].callerId = callerId or ""
						trspta[#trspta].status = status or ""
						trspta[#trspta].idx = idx or ""
						trspta[#trspta].rawdata = "+CMGL: "..line
						print(string.format("idx:'%s'\n\tst:'%s',\n\tcId:'%s',\n\tnada:'%s',\n\tfecha:'%s',\n\tmsg:'%s'",idx, status, callerId, idbook, fecha, msg))
						print(udh_parts,msg:sub(8))
--						command(dev,string.format('+CMGD=%s', idx))
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
--				print("////////////////////////////////////")
				end
			end
		end
	else -- Modo texto no soportado
		print("Modo Texto no Soportado")
	end
	return trspta
end
--[[
function myMsg (dev,nro,msg)
	local tosend = string.format('AT+CMGS="%s"\r%s%s',nro,msg,string.char(26))
	print(tosend)
	dev:write(tosend)
	rspta = leer(dev)
	print(rspta)
end

function myMsg1 (dev,nro,msg)
	local tosend = string.format('AT+CMGS="%s",129\r%s%s',nro,msg,string.char(26))
	print(tosend)
	dev:write(tosend)
	rspta = leer(dev)
	print("R Msg1", rspta)
end
]]
function myMsg2 (dev,nro,msg)
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

function sendMessage(dev, nro, msg)
	local str, serr = command(dev,"+CMGF=1")
	str, serr = command(dev,"+CSMS=1")
	str, serr = command(dev,'+CPMS="SM"')
	str, serr = command(dev,"+CMGF=1")
	str, serr = command(dev,'+CSCS="GSM"')
	str, serr = command(dev,'+CMEE=1')
 

--	myMsg(dev,nro,msg)
--	myMsg1(dev,nro,"Msg1"..msg)
--	myMsg2(dev,"+543722380337",msg)
	myMsg2(dev,nro,msg)

end
--[[
		command(devs[a],"+CSTA?")
		command(devs[a],"+CSTA=?")
		command(devs[a],"+CEER?")
		command(devs[a],"+CEER=?")
		command(devs[a],"+CREG?")
		command(devs[a],"+CREG=?")
		command(devs[a],"+CREG=0")
--		command(devs[a],"+COPN") --List de  Nombre del proveedor
--		command(devs[a],"+COPN?") -- Nombre del proveedor
--		command(devs[a],"+COPN=?") -- Nombre del proveedor
		command(devs[a],"+COPS?") -- Nombre del proveedor
--		command(devs[a],"+COPS=?") -- Lista de señales disponibles
		command(devs[a],"+CSQ?") --Signal level
		command(devs[a],"+CSQ=?") -- Signal level
		command(devs[a],"+CGREG?") -- gprs network resistration status
		command(devs[a],"+CGREG=?") -- lista de gprs oportadas

		command(devs[a],"+CGSMS?")
		command(devs[a],"+CGSMS=?")
		
		command(devs[a],"+CSMS?")
		command(devs[a],"+CSMS=?")
		command(devs[a],"+CSMS=1")
	str, serr = command(dev,"+CPMS?")
	str, serr = command(dev,"+CPMS=?")	
	str, serr = command(dev,'+CPMS="SM"')
	str, serr = command(dev,"+CMGF=1")
	str, serr = command(dev,"+CSMP?")
	str, serr = command(dev,"+CSMP=?")
	str, serr = command(dev,"+CSCA?") -- obtiene el gateway y el modo 
	str, serr = command(dev,"+CSCA=?") -- debería listar los modos disponibles
--	str, serr = command(dev,'+CSCA="+541151740011",145')
		
	str, serr = command(dev,'+CRES=?')
	str, serr = command(dev,'+CMGS?')

	str, serr = command(dev,'+CSCS?')
	str, serr = command(dev,'+CSCS=?')
		command(devs[a],"+CNUM")
		command(devs[a],"+CNUM=?")
]]	
--[[
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
]]
function showRspta(trspta,dbCon)
	for k, t in pairs(trspta) do
--		print(k, t)
		t.fecha = "20"..t.fecha:gsub("/","-")
		t.fecha = t.fecha:gsub(","," ")
		print (t.fecha, t.callerId, t.msg)
--		saveMsg(t,dbCon)
	end
end

--	local ldevs = findModem()
--	local ldevs = {"/dev/ttyUSB0","/dev/ttyUSB4","/dev/ttyUSB7"}
--	local modems = checkModem(ldevs)
--	local dbCon = openDB()
--	sendMessage(modem["/dev/ttyUSB0"].dev, "+543722380337", "570.230.120.120.120.110.110.110")
--	sendMessage(modem["/dev/ttyUSB0"].dev, "+543722380337", "571.240.120.120.120.120.120.120")
--	sendMessage(modem["/dev/ttyUSB0"].dev, "+543722380337", "572.250.120.120.120.130.130.130")
--	socket.sleep(10)
--[[
	for k, t in pairs(modems) do
		if t.enabled then
			print(k, t.marca.text, "Ready")
			showRspta(text_getList(t), dbCon)
		else
			print(k, t.marca.text, "Not Ready")
		end
	end
]]
	dev = openPort("/dev/ttyUSB0")
	rspta = text_getList(dev)
--[[
for _, a in ipairs({2,3}) do
	dev = devs[a]
	command(dev,"+CGMI")
end
--end
]]

--sendMessage(devs[3],"+543722380337","Esta es una prueba sin codigo")
--sendMessage(devs[3],"3722380337","Esta es otra prueba sin codigo")

--sendMessage(devs[5],"3722380337","Esta es una Prueba")