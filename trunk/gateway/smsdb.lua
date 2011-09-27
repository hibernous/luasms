require "luasql.mysql"
mysql = luasql.mysql()

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

function saveMsg(t,dbCon)
	local vt = isVoto(t,dbCon)
	(t.mem, t.idx, t.status, t.sender, t.fecha, t.concat, t.part_id, t.part_idx, t.parts, "\n"..t.msg)
	sql = string.format([[INSERT INTO recibe (fecha, callerId, text, smsraw, procesado)
	VALUES ('%s', '%s', '%s', '%s', '%s')]], t.fecha, t.sender, addslashes(t.msg), addslashes(t.rawdata), vt)
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
