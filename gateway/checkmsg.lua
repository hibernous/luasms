-- Se debe tener instalado 
socket = require("socket")
rs232 = require ("luars232")
require "luasql.mysql"
mysql = luasql.mysql()

--json = require("json")
port = arg[1]
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

function dbConStatus(dbCon)
	if dbCon == nil then
		return false
	end
	if tostring(dbCon):match("(closed)")
	then
		return false
	else
		return true
	end
end

function openDB()
	local host = "172.17.0.56"
	local connMy, serr = mysql:connect("sms","root", "pirulo", host)
	if not connMy then
--		printDL(2,"Error al conectar con MySql en Host: "..host)
		printDL(2,serr)
	end
	return connMy
end

function doSQL(dbCon,str)
	local rslt, serr = nil, nil
	if dbConStatus(dbCon) then
		rslt, serr = dbCon:execute(str)
		if serr then
			printDL(2,string.format("doSql:'%s'\tstatement: '%s'", serr, str))
			if serr:match("Error en el vínculo de comunicación") 
			or serr:match("MySQL server has gone away")
			then
				dbCon:close()
			end
		end
	else
		serr = "No esta conectado al servidor de Base de Datas"
	end
	return rslt, serr
end

function openPort(rsport)
	e, dev = rs232.open(rsport)
	local info
	if e ~= rs232.RS232_ERR_NOERROR then
		-- handle error
		info = string.format("can't open serial port '%s', error: '%s'\n",
		rsport, rs232.error_tostring(e))
	else
		assert(dev:set_baud_rate(rs232.RS232_BAUD_115200) == rs232.RS232_ERR_NOERROR)
		assert(dev:set_data_bits(rs232.RS232_DATA_8) == rs232.RS232_ERR_NOERROR)
		assert(dev:set_parity(rs232.RS232_PARITY_NONE) == rs232.RS232_ERR_NOERROR)
		assert(dev:set_stop_bits(rs232.RS232_STOP_1) == rs232.RS232_ERR_NOERROR)
		assert(dev:set_flow_control(rs232.RS232_FLOW_OFF)  == rs232.RS232_ERR_NOERROR)
		info = string.format("OK, port open with values '%s'", tostring(dev))
	end
	return dev, info
end

function addslashes(s)
	local s = s or ""
	s = string.gsub(s, "(['\"\\])", "\\%1")
	return (string.gsub(s, "%z", "\\0"))
end

function procesaRespuesta(str)
	local rspta = {}
	local tmsgs = {}
	local j = split(str, "+CMGL: ")
	for i, line in ipairs(j) do
--	for mem, i, e in string.gfind(str,'"(%a+)",(%d+),(%d+)',2) do
--		tmsgs[mem] = {cnt=i, of=e}
	end
end

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

function trim (str)
	if str == nil then return "" end
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end


function split(str,sep)
	local t = {}
	local ini = 1
	local seplen = string.len(sep)
	local len = string.len(str)
	local iend= string.find(str,sep,ini,true)
	if iend == nil then iend = len+1 end
	repeat
		t[#t+1] = trim(string.sub(str,ini,iend-1))
		ini = iend+seplen
		iend = string.find(str,sep,ini,true)
	until iend == nil
	if ini <= len+1 then 
		t[#t+1] = trim(string.sub(str,ini))
	end
	return t
end

function readMessages(modem)
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
--			print("============================================")
--			print(str)
--			print("============================================")
				local j = split(rspta.text, "+CMGL: ")
				for i, line in ipairs(j) do
--				print("------------------------------")
--				print(i,line)
					local s, e, status = string.find(line,"\r\n\r\n(%w+)")
--				print("Find Status =",s,e,status)
					if s and e and status then
						line = line:sub(1,s-1)
					end
--				print("------------------------------")
--				print("////////////////////////////////////")
					for idx, status, callerId, nada, fecha, msg in string.gfind(line, '(%d+),"([^"]*)","([^",]*)",([^,]*),"([^"]*)"\r\n(.+)') do
						trspta[#trspta+1] = {}
						trspta[#trspta].mem = k
						trspta[#trspta].dev = modem.dev
						trspta[#trspta].cmd = "+CMGL: "
						trspta[#trspta].msg = msg or ""
						trspta[#trspta].fecha = fecha or ""
						trspta[#trspta].nose = nada or ""
						trspta[#trspta].callerId = callerId or ""
						trspta[#trspta].status = status or ""
						trspta[#trspta].idx = idx or ""
						trspta[#trspta].rawdata = "+CMGL: "..line
--					print(string.format("idx:'%s'\n\tst:'%s',\n\tcId:'%s',\n\tnada:'%s',\n\tfecha:'%s',\n\tmsg:'%s'",idx, status, callerId, nada, fecha, msg))
--					command(dev,string.format('+CMGD=%s', idx))
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

function saveMsg(t,dbCon)
	local vt = isVoto(t,dbCon)
	sql = string.format([[INSERT INTO recibe (fecha, callerId, text, smsraw, procesado)
	VALUES ('%s', '%s', '%s', '%s', '%s')]], t.fecha, t.callerId, addslashes(t.msg), addslashes(t.rawdata), vt)
	print(sql)
	local rslt, serr = doSQL(dbCon,sql)
	if serr == nil then
--		sendMessage(t.dev, t.callerId, t.msg)
		rspta, str, serr = command(t.dev,string.format('+CPMS="%s"',t.mem))
		trspta = command(t.dev,string.format('+CMGD=%s', t.idx))
		print("Borra Reg"..t.idx,trspta.status,trspta.text)
	end
	print ("--------")
	print (t.msg)
	print ("--------")
	print (t.rawdata)
	print ("--------")
end

function showRspta(trspta,dbCon)
	for k, t in pairs(trspta) do
		print(k, t)
		t.fecha = "20"..t.fecha:gsub("/","-")
		t.fecha = t.fecha:gsub(","," ")
--		print (t.fecha, t.callerId, t.msg)
		saveMsg(t,dbCon)
	end
end

--	local ldevs = findModem()
	local ldevs = {"/dev/ttyUSB0","/dev/ttyUSB4","/dev/ttyUSB7"}
	local modems = checkModem(ldevs)
	local dbCon = openDB()
	sendMessage(modem["/dev/ttyUSB0"].dev, "+543722380337", "570.230.120.120.120.110.110.110")
	sendMessage(modem["/dev/ttyUSB0"].dev, "+543722380337", "571.240.120.120.120.120.120.120")
	sendMessage(modem["/dev/ttyUSB0"].dev, "+543722380337", "572.250.120.120.120.130.130.130")
	socket.sleep(10)
	for k, t in pairs(modems) do
		if t.enabled then
			print(k, t.marca.text, "Ready")
			showRspta(readMessages(t), dbCon)
		else
			print(k, t.marca.text, "Not Ready")
		end
	end

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