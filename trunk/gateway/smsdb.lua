require "luasql.mysql"
mysql = luasql.mysql()

function dbConStatus(dbCon)
	if dbCon == nil then
		return false
	end
	if tostring(dbCon):match("(closed)")
	or tostring(dbCon):match("ERROR")
	then
		return false
	else
		return true
	end
end

function mysqlEscape(s)
	if s then
		s = string.gsub(s,"'", function (b) 
			return "\\"..b 
			end)
		s = string.gsub(s,'"', function (b) 
			return "\\"..b 
			end)
		s = string.gsub(s,'%c', function (b)
			if string.byte(b) == 0 then
				return "\\0"
			elseif string.byte(b) == 8 then
				return "\\b"
			elseif string.byte(b) == 9 then
				return "\\t"
			elseif string.byte(b) == 10 then
				return "\\n"
			elseif string.byte(b) == 13 then
				return "\\r"
			elseif string.byte(b) == 26 then
				return ""
			end
			end)
		s = string.gsub(s,'_', function (b) 
			return "\\"..b 
			end)
		s = string.gsub(s,'%%', function (b) 
			return "\\"..b 
			end)
	end
	return s
end
--[[
Escape Sequence Character Represented by Sequence 
\0  An ASCII NUL (0x00) character. 
\'  A single quote (“'”) character. 
\"  A double quote (“"”) character. 
\b  A backspace character. 
\n  A newline (linefeed) character. 
\r  A carriage return character. 
\t  A tab character. 
\Z  ASCII 26 (Control+Z). See note following the table. 
\\  A backslash (“\”) character. 
\%  A “%” character. See note following the table. 
\_  A “_” character. See note following the table. 
]]

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
			printDL(2,string.format("doSql:'%s'\n\tstatement: '%s'", serr, str))
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

function saveMsg(t,com,dbCon)
	vt = "0"
--	local vt = isVoto(t,dbCon)
	sql = string.format([[INSERT INTO recibe (
		`fecha`, 
		`concat`, 
		`partId`, 
		`partNr`, 
		`parts`, 
		`callerId`,
		`dst`,
		`msg`, 
		`smsraw`, 
		`procesado`,
		`gateway`,
		`modem`,
		`port`,
		`IMSIdentity`,
		`operator`
		)
	VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s' )]], 
		t.fecha, 
		t.concat, 
		t.part_id, 
		t.part_idx, 
		t.parts, 
		t.sender, 
		com.number,
		mysqlEscape(t.msg), 
		mysqlEscape(t.fullmsg), 
		vt,
		com.gateway,
		string.format("%s-%s SN(%s)",tostring(com.marca), tostring(com.modelo), tostring(com.serialNumber)),
		com.port,
		com.IMSIdentity,
		com.operator
		)
	local rslt, serr = doSQL(dbCon,sql)
	if serr == nil then
		sql = string.format([[INSERT INTO envia (tonumber, msg)
		VALUES ('%s', '%s')]], t.sender, "SMS recibido")
		doSQL(dbCon,sql)
		rspta, str, serr = command(t.dev,string.format('+CPMS="%s"',t.mem))
		trspta = command(t.dev,string.format('+CMGD=%s', t.idx))
		print("Borra Reg"..t.idx,trspta.status,trspta.text)
	end
end
