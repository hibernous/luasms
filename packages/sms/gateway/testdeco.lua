require ("smscommon")

function decode(rstr)
	local str = rstr
	local trspta = {}
	hl, str 					= getReg(str,2)
	hl = tonumber(hl,16)
	numbering_plan, str 		= getReg(str,2)
	numbering_plan = tonumber(numbering_plan,16)
	gateway, str 				= getReg(str,((hl-1)*2))
	first_oct_sms, str 			= getReg(str,2)
	len_of_add, str 			= getReg(str,2)
	len_of_add = tonumber(len_of_add,16)
	local plus = len_of_add % 2
	address_type, str 			= getReg(str,2)
	sender, str 				= getReg(str,len_of_add+plus)
	protocol_identifier, str 	= getReg(str,2)
	coding_scheme, str 			= getReg(str,2)
	fecha, str 					= getReg(str,14)
	len_of_data, str 			= getReg(str,2)
	len_of_data = tonumber(len_of_data, 16)

	gateway = gateway:gsub("%d%d", function(s)
		return s:reverse()
		end)

	sender = sender:gsub("..", function(s)
		return s:reverse()
		end)
	sender = sender:sub(1,len_of_add)

	fecha = fecha:gsub("%d%d", function(s)
		return s:reverse()
		end)
	fecha = fecha:gsub("(%d%d)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d)", "20%1-%2-%3 %4:%5:%6+%7")

	print("Header Len: "..hl)
	print("Numbering Plan: "..numbering_plan)
	print("GateWay:",gateway)
	print("first_oct_sms",first_oct_sms,tonumber(first_oct_sms,16))
	print("len_of_add",len_of_add)
	print("address_type",address_type)
	print("Print Sender: ",sender)
	print("Protocol Id: ",protocol_identifier)
	print("Codificacion: ",coding_scheme)
	print("Fecha:",fecha)
	print("len_of_data",len_of_data)

	trspta.sender = sender
	trspta.fecha = fecha
	trspta.concat= "0,0,0"
	trspta.part_id = 0
	trspta.parts = 1
	trspta.part_idx = 1
	local i = 1
	local msg = ""
	if tonumber(first_oct_sms,16) >= 64 then
		udhline = str:sub(i,i+15)
		udh_bytes, udhline = getReg(udhline,2)
		udh_concat_indicator, udhline = getReg(udhline,2)
		udh_bytes_follows, udhline = getReg(udhline, 2)
		udh_id, udhline = getReg(udhline, 2)
		udh_parts, udhline = getReg(udhline, 2)
		udh_idx, udhline = getReg(udhline, 2)
		trspta.concat= string.format("%s,%s,%s",udh_bytes,udh_concat_indicator,udh_bytes_follows)
		trspta.part_id = udh_id
		trspta.parts = udh_parts
		trspta.part_idx = udh_idx
--[[
		print("udh_bytes", tonumber(udh_bytes,16))
		print("udh_concat_indicator", tonumber(udh_concat_indicator,16))
		print("udh_bytes_follows", tonumber(udh_bytes_follows,16))
		print("udh_id", tonumber(udh_id,16))
		print("udh_parts", tonumber(udh_parts,16))
		print("udh_idx", tonumber(udh_idx,16))
]]		
		tmpline = decompress(str:sub(i,i+15))
		i = i + 14
		if coding_scheme == "00" then
		for z=tonumber(udh_bytes,16)+3, tmpline:len() do
--			print(tmpline:sub(z,z))
			msg = msg..tmpline:sub(z,z)
		end
		end
	end
	if coding_scheme == "08" then
		msg = msg .. hex162char(str:sub(i-2))
	elseif coding_scheme == "04" then
		msg = msg .. hex82char(str:sub(i-2))
	elseif coding_scheme == "00" then
		msg = msg..decompress1(str:sub(i))
	else
		msg = msg .. hex82char(str:sub(i-2))
	end
--[[
	while i < str:len() do
		print(i, i+15, str:sub(i,i+15))
		msg = msg..'|'..decompress(str:sub(i,i+15))
		i = i + 14
	end
	print(i, i+15, str:sub(i,i+15))
	msg = msg..'|'..decompress(str:sub(i,i+15))
]]
	trspta.msg = msg
--	print (msg)
	return trspta, msg
end


ldevs = {
	{ port = "/dev/ttyUSB0", number = "+543722380337" }
}

local modems = setModem(ldevs,"matrix")
local gateway = "matrix"
for _, com in pairs(modems) do

	readAllMessages(com)
	local rspta, text, status, str, serr =command(dev,"+CMGF=0") 		-- Setea Modo PDU
	rspta, text, status, fullstr, serr  = command(dev,'+CMGL=4')
	print(text)
	local j = split(rspta.text, "+CMGL: ")
	for i, line in ipairs(j) do
		local _, _, idx, status, inbook, octLen, msg = string.find(line,'([^,]*),([^,]*),([^,]*),([^,]*)\r\n(.*)')
		if msg then
			print(decode(msg))
		end
	end
		
		
end