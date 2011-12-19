require "luasql.mysql"mysql = luasql.mysql()mol, serr = mysql:connect("molinetes","root", "pirulo","172.17.0.56") dbo, serr = mysql:connect("dbo_molinetes","root", "pirulo","172.17.0.56") require("lua/fds")es = {}es["0"] = "Entra"es["1"] = "Sale"es["2"] = "Buzon"es["3"] = "N-Buzon"es["4"] = "N-Entra"es["5"] = "N-Sale"if not mol then	print(serr)	os.exit(1)endfunction addslashes(s)  if s == nil then return s end  s = string.gsub(s, "(['\"\\])", "\\%1")  return (string.gsub(s, "%z", "\\0"))endfunction trim (str)	if str == nil then return "" end	return string.gsub(str, "^%s*(.-)%s*$", "%1")endfunction fixNames(str)	if str == nil then return "" end	local str = str:lower()	t = {}	for name in string.gmatch(str,"%S+") do		t[#t+1]= name:gsub("%a", string.upper, 1)	end	str = ""	for i=1, #t do		str = str..t[i].." "	end	str = trim(str)	str = addslashes(str)	return strendfunction getTipoDocumento(str)	local cur = dbo:execute(string.format("SELECT TiposDocumento_id FROM TiposDocumento WHERE id='%s'",str))	return cur:fetch()endfunction getTarjeta(str)	local cur, serror = dbo:execute(string.format("SELECT Numero FROM Tarjetas WHERE id='%s'",str))	if cur then		return cur:fetch()	else		print("No encontro Tarjeta")		print(serror)	endendfunction getCiudadano(str)	local cur, serror = dbo:execute(string.format("SELECT ciudadanos_id FROM Ciudadanos WHERE id='%s'",str))	if cur then		return cur:fetch()	else		print("No econtro Ciudadano")		print(serror)	end	return nilendfunction getCiudadanoVisitante(str)	local cur, serror = dbo:execute(string.format("SELECT Ciudadano FROM Visitantes WHERE id='%s'",str))	if cur then		local ciudadano = cur:fetch()		return getCiudadano(ciudadano)	else		print("No encontro Visitante")		print(serror)	end	return nilendfunction getIniDate(str)	local cur, serror = dbo:execute(string.format("SELECT MIN(FechaHora) AS FechaHora FROM Fichadas WHERE Tarjeta='%s'",str))	if cur then		local ret = cur:fetch()		if ret == nil then			local cur1, serror = dbo:execute(string.format("SELECT FechaHora FROM HST_Personal WHERE Tarjeta='%s'",str))			return cur1:fetch()		else return ret end	else		print("No econtro Ciudadano")		print(serror)	end	return nilend	function trans_TiposDocumentos()	local tpdoc = {}	dropTable("tpdoc")	print("Transfiriendo Tipos de Documentos")	local cur, serror = dbo:execute("SELECT * FROM TiposDocumento")	if cur then		local row = cur:fetch ({}, "a")		while row do			tpdoc[row.Id] = row.TiposDocumento_id			sql = string.format("INSERT INTO tpdoc SET id='%s', code='%s', name='%s' ON DUPLICATE KEY UPDATE code='%s'", row.TiposDocumento_id, row.Descripcion, row.Descripcion, row.Descripcion)			graba(sql)			row = cur:fetch ({}, "a")		end	else		print(serror)	end	return tpdocendfunction trans_Ciudadanos ()	tpdoc = trans_TiposDocumentos()	sql = [[		SELECT Ciudadano, (SELECT Oficinas_id FROM `dbo_molinetes`.`Oficinas` WHERE Oficinas.Id=Oficina) AS idoficina FROM `dbo_molinetes`.`Personal`;	]]	local perso = {}	local cur, serr = dbo:execute(sql)	local row = cur:fetch ({}, "a")	while row do		print(row.Ciudadano, row.idoficina)		perso[row.Ciudadano] = row.idoficina		row = cur:fetch ({}, "a")	end	cur:close()	dropTable("ofi_mov")	dropTable("personas")	dropTable("fotos")	dropTable("operadores")	mol:execute([[INSERT INTO operadores  SET	idoperador = '1',	logname = "SYSTEM",	funciones = CHAR(255)]])	print("Seleccionando Ciudadanos")	sql = [[SELECT * FROM (	SELECT 		Ciudadanos AS Id, 		Apellido, 		Nombre, 		TipoDocumento, 		NumeroDocumento, 		Foto,		Direccion, 		Telefonos 	FROM `dbo_molinetes`.`HST_Ciudadanos`UNION	SELECT 		Id, 		Apellido, 		Nombre, 		TipoDocumento, 		NumeroDocumento,		Foto,		Direccion, 		Telefonos 	FROM `dbo_molinetes`.`Ciudadanos`) SUMC GROUP BY Id]]	local nreg = 0	cur, serr = dbo:execute(sql)	local row = cur:fetch ({}, "a")	while row do 		if row.NumeroDocumento then			nreg = nreg + 1			local tpd = tpdoc[row.TipoDocumento]			local id = nreg --row.Ciudadanos_id			local old_id = row.Id			local apellidos = fixNames(row.Apellido)			local nombres = fixNames(row.Nombre)			local data = addslashes(row.Foto)			local filename = tpd..row.NumeroDocumento..apellidos:gsub(" ", "")			local alt = apellidos.." "..nombres			sqlp = string.format([[INSERT INTO personas SET			id='%s',			old_id='%s',			tpdoc='%s',			nrodoc='%s',			apellidos='%s',			nombres='%s']], id, old_id, tpd, row.NumeroDocumento, apellidos, nombres )			graba(sqlp)			if data then				sqlf = string.format([[INSERT INTO fotos SET				id='%s',				filename='%s',				mimeType='image/jpeg',				alt='%s',				data='%s']], id, filename, alt, data)--				graba(sqlf)				rslt, serr = mol:execute(sqlf)				if serr then					print(serr, sqlf)				end			end			if perso[old_id] then				sqlof = string.format(				[[					INSERT INTO ofi_mov SET						fecha=NOW(),						tipo="Confirmado",						idoficina='%s',						idpersona='%s',						idoperador='1'				]], perso[old_id], id)				graba(sqlof)			end			print(tpd, row.NumeroDocumento, apellidos..", "..nombres)		end		row = cur:fetch ({}, "a")	end	cur:close()end--[[function trans_TarjetasVisitantes()	print("Transfiriendo Tarjetas Visitantes")	local cur, serror = dbo:execute("SELECT * FROM Visitantes_Tarjetas")	if cur then		local row = cur:fetch ({}, "a")		while row do			if row.Tarjeta then				local ciudadano = getCiudadanoVisitante(row.Visitante)				local tarjeta = getTarjeta(row.Tarjeta)				local fecha = row.Alta or os.date()				if tarjeta then					local status = 5					sql = string.format("INSERT into tarjetas SET trj_nro='%s', fecha='%s', status='%s', codigo='%s'", tarjeta, fecha, status, ciudadano)					graba(sql)					if row.Baja then						fecha = row.Baja						status = 2						sql = string.format("INSERT into tarjetas SET trj_nro='%s', fecha='%s', status='%s', codigo='%s'", tarjeta, fecha, status, ciudadano)						graba(sql)					end				end			end			row = cur:fetch ({}, "a")		end	else		print(serror)	endendfunction trans_TarjetasPersonal()	print("Transfiriendo Tarjetas Personal")	local cur, serror = dbo:execute("SELECT * FROM Personal")	if cur then		local row = cur:fetch ({}, "a")		while row do			if row.Tarjeta then				local ciudadano = getCiudadano(row.Ciudadano)				local tarjeta = getTarjeta(row.Tarjeta)				local status = 3				if tarjeta then					local fecha = getIniDate(row.Tarjeta)					sql = string.format("INSERT into tarjetas SET trj_nro='%s', fecha='%s', status='%s', codigo='%s'", tarjeta, fecha, status, ciudadano)					graba(sql)				end			end			row = cur:fetch ({}, "a")		end	else		print(serror)	endend]]function saveTrjMov(trj)	local str = string.format([[INSERT INTO trj_mov SET fecha='%s', tarjeta='%s', tipo='%s', de='%s', a='%s', funciones='%s']], trj.fecha, trj.tarjeta, trj.tipo, trj.de, trj.a, addslashes(trj.funciones))	graba(str)endfunction trans_Fichadas()	-- Transferir Molinetes	dropTable("prs_mov")	dropTable("tarjetas")	dropTable("trj_mov")	dropTable("ctrls")	dropTable("ctrls_mov")	local sql = string.format([[SELECT * FROM `dbo_molinetes`.`Molinetes`]])	local cur, serr = dbo:execute(sql)	if serr then 		print(serr)		os.exit(0)	end	local ctrls = {}	local row = cur:fetch ({}, "a")	while row do		local sqlctrl = string.format([[INSERT INTO ctrls SET 	idctrl='%s',	name='%s',	macaddrs='%s']], row.Numero, row.Descripcion, row.MACAdd)		ctrls[row.Id] = row.Numero		graba(sqlctrl)		row = cur:fetch ({}, "a")	end	cur:close()sql = [[SELECT     (SELECT id FROM `molinetes`.`personas` WHERE Ciudadano=personas.old_id) AS Ciudadano,     (SELECT numero FROM `dbo_molinetes`.`Tarjetas` WHERE `dbo_molinetes`.`Tarjetas`.`Id`=Tarjeta) AS Tarjeta,     FechaHora,     (SELECT Numero FROM `dbo_molinetes`.`Molinetes` WHERE `dbo_molinetes`.`Molinetes`.`Id`=Molinete) AS Molinete, 	Sensor,    IF (UF.Sensor=0, "Entra", IF (UF.Sensor=1, "Sale", IF (UF.Sensor=2,"Devuelve","Error"))) AS TipoFROM (    SELECT * FROM `dbo_molinetes`.`HST_FICHADAS`    UNION    SELECT * FROM `dbo_molinetes`.`Fichadas`) UF group by Ciudadano, Tarjeta, Molinete, Tipo, FechaHora ORDER BY FechaHora]]sql = [[SELECT     (SELECT id FROM `molinetes`.`personas` WHERE Ciudadano=personas.old_id) AS Ciudadano,     (SELECT numero FROM `dbo_molinetes`.`Tarjetas` WHERE `dbo_molinetes`.`Tarjetas`.`Id`=Tarjeta) AS Tarjeta,     FechaHora,     (SELECT Numero FROM `dbo_molinetes`.`Molinetes` WHERE `dbo_molinetes`.`Molinetes`.`Id`=Molinete) AS Molinete, 	Sensor,    IF (UF.Sensor=0, "Entra", IF (UF.Sensor=1, "Sale", IF (UF.Sensor=2,"Devuelve","Error"))) AS TipoFROM (    SELECT * FROM `dbo_molinetes`.`HST_FICHADAS`    UNION    SELECT * FROM `dbo_molinetes`.`Fichadas`) UF ORDER BY FechaHora]]	local desde = 1	local limit = 100000	local valid = 0	local invalid = 0	local duplicate = 0	local eduplicate = 0	print("Leyendo Fichadas")	cur, serr = dbo:execute(string.format("%s LIMIT %d, %d",sql,desde,limit))	if serr then		print(serr)		os.exit(0)	end	while cur do		local leyo = cur:numrows()		if leyo > 0 then			desde = desde + leyo			local row = cur:fetch ({}, "a")			while row do				row.Sensor = tonumber(row.Sensor)				if row.Tarjeta then					local trj = string.format([[INSERT INTO tarjetas SET idtarjeta='%s', lecturas=1, created='%s', last=NOW()ON DUPLICATE KEY UPDATE lecturas=lecturas+1, last='%s']], row.Tarjeta, row.FechaHora, row.FechaHora )					graba(trj)				end				if row.Sensor < 3 then					if row.Tarjeta then					local ftrjmov = string.format([[SELECT * FROM trj_mov WHERE tarjeta='%s' ORDER BY idtrj_mov desc limit 1]], row.Tarjeta )					local tmov = {}					tmov.fecha = row.FechaHora					tmov.tarjeta = row.Tarjeta					local tmcur, serr = mol:execute(ftrjmov)					if serr then						print(serr)						os.exit(0)					end					if tmcur:numrows() == 1 then						tmov = tmcur:fetch ({}, "a")						if row.Sensor == 0 then							if row.Ciudadano then								if tmov.tipo == "ASIGNA" then									if tonumber(tmov.a) ~= tonumber(row.Ciudadano) then										tmov.fecha = row.FechaHora										tmov.tipo = "DEVUELVE"										tmov.de = tmov.a										tmov.a = 1										tmov.funciones = ""										saveTrjMov(tmov)										tmov.tipo = "ASIGNA"										tmov.de = 1										tmov.a = row.Ciudadano										tmov.funciones = string.char(3)										saveTrjMov(tmov)									end								elseif tmov.tipo == "DEVUELVE" then									tmov.tipo = "ASIGNA"									tmov.de = 1									tmov.a = row.Ciudadano									tmov.funciones = string.char(3)									saveTrjMov(tmov)								end							end						elseif row.Sensor == 1 then							if row.Ciudadano then								if tmov.tipo == "ASIGNA" then									if tonumber(tmov.a) ~= tonumber(row.Ciudadano) then										tmov.fecha = row.FechaHora										tmov.tipo = "DEVUELVE"										tmov.de = tmov.a										tmov.a = 1										tmov.funciones = ""										saveTrjMov(tmov)										tmov.tipo = "ASIGNA"										tmov.de = 1										tmov.a = row.Ciudadano										tmov.funciones = string.char(3)										saveTrjMov(tmov)									end								else									tmov.fecha = row.FechaHora									tmov.tipo = "ASIGNA"									tmov.de = 1									tmov.a = row.Ciudadano									tmov.funciones = string.char(3)									saveTrjMov(tmov)								end							end						elseif row.Sensor == 2 then							if row.Ciudadano then								if tmov.tipo == "ASIGNA" then									if tonumber(row.Ciudadano) ~= tonumber(tmov.a)									then										tmov.fecha = row.FechaHora										tmov.tipo = "DEVUELVE"										tmov.de = tmov.a										tmov.a = 1										tmov.funciones = ""										saveTrjMov(tmov)									-- Asigna										tmov.tipo = "ASIGNA"										tmov.de = 1										tmov.a = row.Ciudadano										tmov.funciones = string.char(3)										saveTrjMov(tmov)										tmov.tipo = "DEVUELVE"										tmov.de = row.Ciudadano										tmov.a = 1										tmov.funciones = ""										saveTrjMov(tmov)									else										tmov.fecha = row.FechaHora										tmov.tipo = "DEVUELVE"										tmov.de = row.Ciudadano										tmov.a = 1										tmov.funciones = ""										saveTrjMov(tmov)									end								elseif tmov.tipo == "DEVUELVE" then									if tonumber(row.Ciudadano) ~= tonumber(tmov.de) then										tmov.fecha = row.FechaHora										tmov.tipo = "ASIGNA"										tmov.de = 1										tmov.a = row.Ciudadano										tmov.funciones = string.char(3)										saveTrjMov(tmov)																				tmov.tipo = "DEVUELVE"										tmov.de = row.Ciudadano										tmov.a = 1										tmov.funciones = ""										saveTrjMov(tmov)									end								end							end						end					else						if row.Ciudadano then							if row.Sensor == 0 							or row.Sensor == 1							then								tmov.tipo = "ASIGNA"								tmov.de = 1								tmov.a = row.Ciudadano								tmov.funciones = string.char(3)								saveTrjMov(tmov)							elseif row.Sensor == 2 then								tmov.tipo = "ASIGNA"								tmov.de = 1								tmov.a = row.Ciudadano								tmov.funciones = string.char(3)								saveTrjMov(tmov)								tmov.tipo = "DEVUELVE"								tmov.a = 1								tmov.de = row.Ciudadano								tmov.funciones = ""								saveTrjMov(tmov)							end										end					end					end					if row.Ciudadano and row.Molinete then						local fprsmov = string.format([[SELECT * from prs_mov where fecha='%s' AND es='%s' AND idregister='%s' AND idpersona='%s']], row.FechaHora, row.Tipo:sub(1,1), row.Molinete, row.Ciudadano)						if find(mol,fprsmov) == 0 then							local es = "E"							if row.Sensor > 0 then es = "S" end							local prsmov = string.format([[INSERT INTO prs_mov SET fecha='%s', es='%s', tipo='C', idregister='%s', idpersona='%s']], row.FechaHora, es, row.Molinete, row.Ciudadano)							graba(prsmov)						else						end					end					if row.Molinete and row.Tarjeta then						local fctrmov = string.format([[SELECT * from ctrls_mov where fecha='%s' AND idctrl='%s' AND sensor='%s' AND tarjeta='%s']], row.FechaHora, row.Molinete, row.Sensor, row.Tarjeta)						if find(mol,fctrmov) == 0 then							local ctrlmov = string.format([[INSERT INTO ctrls_mov SET fecha='%s', idctrl='%s', tarjeta='%s', sensor='%s', valid='%s']], row.FechaHora, row.Molinete, row.Tarjeta, row.Sensor, 1)							graba(ctrlmov)						else						end					end				end				row = cur:fetch ({}, "a")			end			cur:close()			print("Procesadas : ", desde-1)			print("Personal   : ", cp)			print("Validas    : ", valid)			print("Ignoradas  : ", invalid)			print("Duplicasas : ", duplicate)			print("EDuplicasas: ", eduplicate)			if leyo == limit then				cur, serr = dbo:execute(string.format("%s LIMIT %d, %d",sql,desde,limit))			else				break;			end		else			break		end	endendfunction trans_Fichadas_old()	sql = [[SELECT Tarjeta FROM Personal]]	local cur, serr = dbo:execute(sql)	if serr then 		print(serr)		os.exit(0)	end	trjPer = {}	local cp = 0	local row = cur:fetch ({}, "a")	while row do		print(row.Tarjeta)		if row.Tarjeta then			cp = cp + 1			trjPer[row.Tarjeta] = true		end		row = cur:fetch ({}, "a")	end	cur:close()	print("Registros Personal: "..cp)	dropTable("molinete_mov")	dropTable("personas_mov")	local es = {}	sql = [[	SELECT 		Fichadas.Fichadas_id AS F_id,		Fichadas.FechaHora AS F_fecha,		Fichadas.Sensor AS F_sensor,		Ciudadanos.Ciudadanos_id AS C_id,		Ciudadanos.Apellido AS C_apellido,		Ciudadanos.Nombre AS C_nombre,		TiposDocumento.TiposDocumento_id AS C_tpdoc,		TiposDocumento.Descripcion AS C_docdes,		Ciudadanos.NumeroDocumento AS C_nrodoc,		Ciudadanos.Foto AS C_foto,		Tarjetas.Tarjetas_id AS T_id,		Tarjetas.Numero AS T_nro,		Molinetes.Molinetes_id AS M_id,		Molinetes.Descripcion AS M_name	FROM Fichadas 	LEFT JOIN (Ciudadanos, TiposDocumento, Tarjetas, Molinetes) 		ON (Ciudadanos.Id=Fichadas.Ciudadano 		AND Ciudadanos.TipoDocumento=TiposDocumento.Id 		AND Tarjetas.Id=Fichadas.Tarjeta 		AND Molinetes.Id=Fichadas.Molinete) ORDER BY Fichadas.FechaHora]]sql = [[	SELECT 		Fichadas.Fichadas_id AS F_id,		Fichadas.FechaHora AS F_fecha,		Fichadas.Tarjeta AS F_Tarjeta,		Molinetes.Molinetes_id AS M_id,		Fichadas.Sensor AS F_sensor,		Ciudadanos.Ciudadanos_id AS C_id,		Tarjetas.Numero AS T_nro	FROM Fichadas 	LEFT JOIN (Ciudadanos, Tarjetas, Molinetes) 		ON (Ciudadanos.Id=Fichadas.Ciudadano 		AND Tarjetas.Id=Fichadas.Tarjeta 		AND Molinetes.Id=Fichadas.Molinete) ORDER BY Fichadas.FechaHora]]sql = [[select * FROM (	SELECT		Id AS F_id,		FechaHora AS F_fecha, 		(SELECT id  FROM molinetes.personas WHERE molinetes.personas.old_id=F.Ciudadano) AS C_id,		(SELECT Molinetes_id FROM Molinetes WHERE Molinetes.Id=F.Molinete) AS M_id,		(SELECT Personal.Tarjeta FROM Personal WHERE F.Ciudadano=Personal.Ciudadano) AS F_Personal,		Sensor AS F_sensor,		(SELECT numero FROM Tarjetas WHERE F.Tarjeta=Tarjetas.Id) AS T_nro	FROM Fichadas Funion	SELECT 		Id AS F_id,		FechaHora AS F_fecha, 		(SELECT id  FROM molinetes.personas WHERE molinetes.personas.old_id=HF.Ciudadano) AS C_id,		(SELECT Molinetes_id FROM Molinetes WHERE Molinetes.Id=HF.Molinete) AS M_id,		(SELECT Personal.Tarjeta FROM Personal WHERE HF.Ciudadano=Personal.Ciudadano) AS F_Personal,		Sensor AS F_sensor,		(SELECT numero FROM Tarjetas WHERE HF.Tarjeta=Tarjetas.Id) AS T_nro	FROM HST_FICHADAS HF) RF WHERE NOT ISNULL(T_nro) AND NOT ISNULL(C_id) AND F_sensor<3 ORDER BY F_fecha]]	local desde = 1	local limit = 100000	local valid = 0	local invalid = 0	local duplicate = 0	local eduplicate = 0	cur, serr = dbo:execute(string.format("%s LIMIT %d, %d",sql,desde,limit))	if serr then		print(serr)	end	while cur do		local leyo = cur:numrows()		if leyo > 0 then			desde = desde + leyo			local row = cur:fetch ({}, "a")			while row do				if serr then 					print(serr)					os.exit(0)				end				if  row.F_sensor				and tonumber(row.F_sensor) < 3				and row.C_id				and row.T_nro				and row.M_id				then					local fisdup = string.format([[					SELECT * FROM molinete_mov						WHERE 	fecha='%s'							AND molinete_id='%s'							AND sensor_id='%s'							AND tarjeta='%s'							AND persona='%s']], row.F_fecha, row.M_id, row.F_sensor, row.T_nro, row.C_id)					local fcur, serr = mol:execute(fisdup)					if fcur:numrows() == 0 then						valid = valid + 1						local personal = 0--					print(row.F_fecha,row.M_id, es[row.F_sensor], row.C_id, row.T_nro)						if trjPer[row.F_Personal] then							personal = 1						end						local sqlm = string.format([[						INSERT INTO molinete_mov SET							fecha='%s',							molinete_id='%s',							sensor_id='%s',							valid='%s',							tarjeta='%s',							personal='%s',							persona='%s'						]],row.F_fecha, row.M_id, row.F_sensor, 1, row.T_nro, personal, row.C_id)						local mtype = "E"						if tonumber(row.F_sensor) > 0 then mtype="S" end						local sqles = string.format([[						INSERT INTO personas_mov SET							fecha='%s',							type='%s',							personaId='%s',							lugar='%s',							captura='A',							personal='%s',							tarjeta='%s'						]],row.F_fecha, mtype, row.C_id, row.M_id, personal, row.T_nro)						local find = string.format([[							SELECT * FROM personas_mov 								WHERE 	fecha='%s' 									AND type='%s'									AND personaId='%s'									AND lugar='%s'									AND tarjeta='%s'							]], row.F_fecha, mtype, row.C_id, row.M_id, row.T_nro)						local fcur, serr = mol:execute(find)						if serr then							print(serr)							os.exit(1)						end						if fcur then							if fcur:numrows() > 0 then								eduplicate = eduplicate + 1							else								graba(sqles)							end						end						graba(sqlm)					else						duplicate = duplicate + 1					end				else					invalid = invalid + 1				end				row = cur:fetch ({}, "a")			end			cur:close()			print("Procesadas : ", desde-1)			print("Personal   : ", cp)			print("Validas    : ", valid)			print("Ignoradas  : ", invalid)			print("Duplicasas : ", duplicate)			print("EDuplicasas: ", eduplicate)			cur, serr = dbo:execute(string.format("%s LIMIT %d, %d",sql,desde,limit))		else			break		end	endendfunction trans_sintarjetas()	sql = [[		SELECT Ciudadanos.Ciudadanos_id AS C_id, Ingreso, Egreso, 			(SELECT Personal_id FROM Personal WHERE Personal.Ciudadano=Ciudadanos.id) AS personal 		FROM IngresosSinTarjeta 		LEFT JOIN (Ciudadanos) 		ON (Ciudadanos.Id=IngresosSinTarjeta.Ciudadano)	]]	cur, serr = dbo:execute(sql)	local row = cur:fetch ({}, "a")	while row do		local personal = 0		if row.personal then personal=1 end		if row.Ingreso then			local sqles = string.format([[				INSERT INTO personas_mov SET				fecha='%s',				type='E',				personaId='%s',				lugar='9999',				captura='M',				personal='%s'			]],row.Ingreso, row.C_id, personal)			graba(sqles)		end		if row.Egreso then			local sqles = string.format([[				INSERT INTO personas_mov SET				fecha='%s',				type='S',				personaId='%s',				lugar='9999',				captura='M',				personal='%s'			]],row.Egreso, row.C_id, personal)			graba(sqles)		end		row = cur:fetch ({}, "a")	endendfunction TarjetasVisitantes()	sql = [[	SELECT * FROM MotivosVisita	]]	cur, serr = dbo:execute(sql)	local row = cur:fetch ({}, "a")	local tmotivo = {}	while row do		tmotivo[row.MotivosVisita_id] = row.Descripcion		row = cur:fetch ({}, "a")	end	cur:close()	sql = [[	SELECT 		(SELECT VV.Ciudadano FROM dbo_molinetes.Visitantes VV			WHERE VV.Id=VT.Visitante) AS TmpC_id, 		(SELECT Ciudadanos_id FROM dbo_molinetes.Ciudadanos CC WHERE TmpC_id=Id) AS C_id, 		(SELECT numero FROM dbo_molinetes.Tarjetas UT WHERE UT.Id=VT.Tarjeta) AS T_nro, 		(SELECT MotivosVisita_id FROM dbo_molinetes.MotivosVisita MV WHERE MV.Id=VT.MotivoVisita) AS M_visita,		Alta,		Baja,		Observaciones  	FROM dbo_molinetes.Visitantes_Tarjetas VT ORDER BY Alta	]]	local desde = 1	local limit = 100000	local valid = 0	local invalid = 0	local duplicate = 0	local eduplicate = 0	cur, serr = dbo:execute(string.format("%s LIMIT %d, %d",sql,desde,limit))	if serr then		print(serr)	end		local leyo = cur:numrows()	while leyo > 0 do		desde = desde + leyo		local row = cur:fetch ({}, "a")		while row do			-- Hace un insert de la tarjeta asignando funciones para visitantes si tarjeta ya existe regraba funciones			print(row.C_id, row.T_nro, row.Alta, row.Baja, tmotivo[row.M_visita], row.Observaciones)			row = cur:fetch ({}, "a")		end		if leyo == limit		then			print("Procesadas : ", desde-1)		else			print("Procesadas : ", desde)		end		cur:close()		cur, serr = dbo:execute(string.format("%s LIMIT %d, %d",sql,desde,limit))		leyo = cur:numrows()	endendfunction TarjetasTemporales()	sql = [[	SELECT 		(SELECT VV.Ciudadano FROM dbo_molinetes.Personal VV			WHERE VV.Id=VT.Personal) AS TmpC_id, 		(SELECT Ciudadanos_id FROM dbo_molinetes.Ciudadanos CC WHERE TmpC_id=Id) AS C_id, 		(SELECT numero FROM dbo_molinetes.Tarjetas UT WHERE UT.Id=VT.Tarjeta) AS T_nro, 		Alta,		Baja	FROM dbo_molinetes.TarjetasTemporales VT ORDER BY Alta	]]	local desde = 1	local limit = 10000	local valid = 0	local invalid = 0	local duplicate = 0	local eduplicate = 0	cur, serr = dbo:execute(string.format("%s LIMIT %d, %d",sql,desde,limit))	if serr then		print(serr)	end		local leyo = cur:numrows()	while leyo > 0 do		desde = desde + leyo		local row = cur:fetch ({}, "a")		while row do			-- Hace un insert de la tarjeta asignando funciones para visitantes si tarjeta ya existe regraba funciones			print(row.C_id, row.T_nro, row.Alta, row.Baja)			row = cur:fetch ({}, "a")		end		if leyo == limit		then			print("Procesadas : ", desde-1)		else			print("Procesadas : ", desde)		end		cur:close()		cur, serr = dbo:execute(string.format("%s LIMIT %d, %d",sql,desde,limit))		leyo = cur:numrows()	endendfunction trans_OrgOfi()	local tpdoc = {}	dropTable("organismos")	local cur, serror = dbo:execute("SELECT * FROM `Organismos`")	if cur then		local row = cur:fetch ({}, "a")		while row do			sql = string.format("INSERT INTO organismos SET idorganismo='%s', code='%s', name='%s' ON DUPLICATE KEY UPDATE code='%s'", row.Organismos_id, row.Codigo, row.Descripcion, row.Codigo)			graba(sql)			row = cur:fetch ({}, "a")		end	else		print(serror)	end	cur:close()	dropTable("oficinas")	cur, serror = dbo:execute([[SELECT Oficinas_id, 	Descripcion, 	(SELECT Organismos_id FROM `dbo_molinetes`.`Organismos` 		WHERE Organismos.Id=Organismo) AS OrgId, 	Codigo 	FROM `dbo_molinetes`.`Oficinas`]])	if cur then		local row = cur:fetch ({}, "a")		while row do			sql = string.format("INSERT INTO oficinas SET idoficina='%s', idorganismo='%s', name='%s', code='%s' ON DUPLICATE KEY UPDATE code='%s'", row.Oficinas_id, row.OrgId, row.Descripcion, row.Codigo, row.Codigo)			graba(sql)			row = cur:fetch ({}, "a")		end	else		print(serror)	endendfunction trans_misc()end--trans_misc()--trans_OrgOfi()--trans_Ciudadanos()trans_Fichadas ()--trans_sintarjetas()--TarjetasVisitantes()--TarjetasTemporales()--trans_TarjetasVisitantes()--trans_TarjetasPersonal()