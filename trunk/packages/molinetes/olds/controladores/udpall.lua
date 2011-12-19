json = require("json")
socket = require("socket")
require "luasql.odbc"
mssql = luasql.odbc()
require "luasql.mysql"
mysql = luasql.mysql()
local hex2bin = {
	["0"] = "0000",
	["1"] = "0001",
	["2"] = "0010",
	["3"] = "0011",
	["4"] = "0100",
	["5"] = "0101",
	["6"] = "0110",
	["7"] = "0111",
	["8"] = "1000",
	["9"] = "1001",
	["a"] = "1010",
	["b"] = "1011",
	["c"] = "1100",
	["d"] = "1101",
	["e"] = "1110",
	["f"] = "1111"
	}
local bin2hex = {
	["0000"] = "0",
	["0001"] = "1",
	["0010"] = "2",
	["0011"] = "3",
	["0100"] = "4",
	["0101"] = "5",
	["0110"] = "6",
	["0111"] = "7",
	["1000"] = "8",
	["1001"] = "9",
	["1010"] = "a",
	["1011"] = "b",
	["1100"] = "c",
	["1101"] = "d",
	["1110"] = "e",
	["1111"] = "f"
	}

function string.hex2bin(s)
	return (string.gsub(s, ".", function (c)
						return hex2bin[string.lower(c)]
         end))
end

function string.bin2hex(s)
	local len = string.len(s)
	local rem = len % 4
	if (rem > 0) then
		s = string.rep("0", 4 - rem)..s
	end
	return (string.gsub(s, "....", function (c)
						return bin2hex[string.lower(c)]
         end))
end

function string.bin2dec(s)

-- s	-> binary string

local num = 0
local ex = string.len(s) - 1
local l = 0

	l = ex + 1
	for i = 1, l do
		b = string.sub(s, i, i)
		if b == "1" then
			num = num + 2^ex
		end
		ex = ex - 1
	end

	return string.format("%u", num)

end



function string.dec2bin(s, num)

-- s	-> Base10 string
-- num  -> string length to extend to

local n

	if (num == nil) then
		n = 0
	else
		n = num
	end
	
	s = string.format("%x", s)

	s = string.hex2bin(s)

	while string.len(s) < n do
		s = "0"..s
	end

	return s

end

function string.hex2dec(s)
-- s	-> hexadecimal string
	local s = string.hex2bin(s)
	return string.bin2dec(s)
end

function string.dec2hex(s)
-- s	-> Base10 string
	s = string.format("%x", s)
	return s
end

function numToint32(s)
	num = tonumber(s)
	if num > 4294967295 then
		io.stderr:write("Error: Can't convert to int32 number > 4294967295\n")
		os.exit(1)
	end
	t = {0,0,0,0}
	i = 4
	while num > 0 do
		local resto = num % 256
		num = math.floor(num/256)
		t[i] = tonumber(resto)
		if num < 256 then
			t[i-1] = num
			num = 0
		end
		i = i - 1
	end
	local str = ""
	for i = 1, 4 do
		str = str..string.char(t[i])
	end
	return str
end

function int32Tonum(s)
	s = string.reverse(s)
	local num = 0
	for i=s:len(), 1, -1 do
		num = num + (string.byte(s,i) * (256 ^ (i-1)))
	end
	return num
end

function sint32Tonum(s)
--	s = string.reverse(s)
	local num = 0
	for i=s:len(), 1, -1 do
		num = num + (string.byte(s,i) * (256 ^ (i-1)))
	end
	return num
end
--------------------------------------------------------------------------------
function string.hexOr(v, m)
-- v	-> hex string to be masked
-- m	-> hex string mask

-- s	-> hex string as masked
-- bv	-> binary string of v
-- bm	-> binary string mask
	local bv = Hex2Bin(v)
	local bm = Hex2Bin(m)
	return string.bin2hex(string.binOr(bv,bm))
end


function string.binOr(bv, bm)
	while ((string.len(bv) %4) ~= 0) do
		bv = "0"..bv
	end
	while ((string.len(bm) %4) ~= 0) do
		bm = "0"..bm
	end
	local lbv = string.len(bv)
	local lbm = string.len(bm)
	local lt = lbv
	local i = 0
	local s = ""

	if lbm > lt then lt = lbm end
	for i = 1, lt do
		cv = string.sub(bv, i, i)
		cm = string.sub(bm, i, i)
		if i > lbv then cv="0" end
		if i > lbm then cm="0" end
		if cv == "1" then
				s = s.."1"
		elseif cm == "1" then
				s = s.."1"
		else
			s = s.."0"
		end
	end
	return s
end

function string.hexXOr(v, m)
-- v	-> hex string to be masked
-- m	-> hex string mask

-- s	-> hex string as masked

-- bv	-> binary string of v
-- bm	-> binary string mask

	local bv = string.hex2bin(v)
	local bm = string.hex2bin(m)
	return string.bin2hex(string.binXOr(bv,bm))
end

function string.binXOr(bv,bm)
	while ((string.len(bv) %4) ~= 0) do
		bv = "0"..bv
	end

	while ((string.len(bm) %4) ~= 0) do
		bm = "0"..bm
	end

	local lbv = string.len(bv)
	local lbm = string.len(bm)
	local lt = lbv
	if lbm > lbv then lt = lbm  end

	local i = 0
	local s = ""

	for i = 1, lt do
		local cv = string.sub(bv, i, i)
		local cm = string.sub(bm, i, i)
		if i > lbv then cv="0" end
		if i > lbm then cm="0" end
		if cv == "1" then
			if cm == "0" then
				s = s.."1"
			else
				s = s.."0"
			end
		elseif cm == "1" then
			if cv == "0" then
				s = s.."1"
			else
				s = s.."0"
			end
		else
			-- cv and cm == "0"
			s = s.."0"
		end
	end
	return s
end

function string.hexNot(v, m)

-- v	-> hex string to be masked
-- m	-> hex string mask

-- s	-> hex string as masked

-- bv	-> binary string of v
-- bm	-> binary string mask

	local bv = string.hex2bin(v)
	local bm = string.hex2bin(m)
	return string.bin2hex(string.binNot(bv,bm))
end

function string.binNot(bv, bm)
	while ((string.len(bv) %4) ~= 0) do
		bv = "0"..bv
	end

	while ((string.len(bm) %4) ~= 0) do
		bm = "0"..bm
	end

	local lbv = string.len(bv)
	local lbm = string.len(bm)
	local lt = lbv
	if lbm > lbv then lt = lbm  end

	local i = 0
	local s = ""
	
	for i = 1, lt do
		local cv = string.sub(bv, i, i)
		local cm = string.sub(bm, i, i)
		if i > lbv then cv="0" end
		if i > lbm then cm="0" end
		if cm == "1" then
			if cv == "1" then
				-- turn off
				s = s.."0"
			else
				-- turn on
				s = s.."1"
			end
		else
			-- leave untouched
			s = s..cv

		end
	end

	return s

end


-- these functions shift right and left, adding zeros to lost or gained bits
-- returned values are 32 bits long

-- BShRight(v, nb)
-- BShLeft(v, nb)


function BShRight(v, nb)

-- v	-> hexstring value to be shifted
-- nb	-> number of bits to shift to the right

-- s	-> binary string of v

	local s = Hex2Bin(v)

	while (string.len(s) < 32) do
		s = "0000"..s
	end

	s = string.sub(s, 1, 32 - nb)

	while (string.len(s) < 32) do
		s = "0"..s
	end

	return Bin2Hex(s)

end

function BShLeft(v, nb)

-- v	-> hexstring value to be shifted
-- nb	-> number of bits to shift to the right

-- s	-> binary string of v

	local s = Hex2Bin(v)

	while (string.len(s) < 32) do
		s = "0000"..s
	end

	s = string.sub(s, nb + 1, 32)

	while (string.len(s) < 32) do
		s = s.."0"
	end
	return Bin2Hex(s)
end

function parityBit(s)
--	if string.len(s) > 0 then
	bit = "00000000"
	for a in string.gmatch(s, ".", "%1") do
		local c = string.dec2bin(string.byte(a))
		if c:len() == 4 then c = "0000"..c end
		bit = string.binXOr(c,bit)
	end
	return (string.char(string.bin2dec(bit)))
--	else
--		return nil
--	end
end

function sendmsg(s)
	local stx="" -- string.char(2)
	local etx="" -- string.char(3)
	local msg = stx..s..etx
	msg = msg..parityBit(msg)
	return msg
end

function openMy()
	local host = "172.17.0.56"
	local connMy, serr = mysql:connect("molinetes","root", "pirulo", host)
	if not connMy then
		print("Error al conectar con MySql en Host: "..host)
		print(serr)
		os.exit(1)
	end
	return connMy
end

function openMS(data)
	local dataSource = data
	local connMS = mssql:connect(dataSource) 
	if not connMS then
		print("Error al conectar MS-SQL con DataSource '"..dataSource)
		os.exit(1)
	end
	return connMS
end

function addslashes(s)
	local s = s or ""
	s = string.gsub(s, "(['\"\\])", "\\%1")
	return (string.gsub(s, "%z", "\\0"))
end

function doTra(dbCon,str)
--	print(str)
	local rslt, serr = dbCon:execute(sql)
end

function getCur(dbCon, sql)
	local cur, serr = dbCon:execute(sql)
	if serr then 
		print(serr) 
		return nil
	end
	return cur
end

function newset()
    local reverse = {}
    local rdata = {}
    local set = {}
	local info = {}
    return setmetatable(set, {__index = {
        insert = function(set, value, data)
            if not reverse[value] then
                table.insert(set, value)
				table.insert(info, data)
                reverse[value] = table.getn(set)
				return value
            end
        end,
		data = function(set, value)
			local index = reverse[value]
			if index then
				return info[index]
			end
		end,
        remove = function(set, value)
            local index = reverse[value]
            if index then
                reverse[value] = nil
				table.remove(info)
                local top = table.remove(set)
                if top ~= value then
                    reverse[top] = index
                    set[index] = top
					info[index] = top
                end
            end
        end
    }})
end

function connectMolinete(r)
	if socket.gettime() - r.reopen < 0 then 
		return nil
	end
--	if r.failopen == 5 then
--		return nil
--	end
	cli, serr = socket.connect(r.host, r.port)
	if serr then
		r.reopen = socket.gettime() + 90
		print(string.format("Error: %s al conectar %s en la ip '%s' puerto %s",serr, r.name, r.host, r.port))
		r.failopen = r.failopen + 1
	else
		r.reopne = socket.gettime()
		cli:settimeout(1,"t")
		set:insert(cli, r)
		print(string.format("Conectado a %s en la ip '%s' puerto %s", r.name, r.host, r.port))
	end
	return cli
end

function tbMolinetes()
	local t = {}
	dbMol = openMS("18")
	sql = "SELECT CAST(Id AS VARCHAR(36)) AS uId, Descripcion, IP, Serie, Numero FROM Molinetes"
	cur = getCur(dbMol, sql)
	local row = cur:fetch ({}, "a")
	while row do
		local n = row.Serie
		if tonumber(row.Numero) < 7 then
		t[n] 			= {}
		t[n].uId		= row.uId
		t[n].numero		= row.Numero
		t[n].serie		= row.Serie
		t[n].name		= row.Descripcion
		t[n].host		= row.IP
		t[n].lastreg    = {}
		t[n].port		= 3010
		t[n].timeout	= 0
		t[n].waiting	= 0
		t[n].waiting	= 0
		t[n].failopen	= 0
		t[n].reopen		= 0
		t[n].last		= 0
		t[n].msg		= ""
		end
		row = cur:fetch ({}, "a")
	end
	return t
end

function decodeMsg(m)
	local r = {}
	r.year = m.time.year
	r.wday = m.time.wday
	r.sec = m.time.sec
	r.status = false
--	print("decodeMsg",m.rspta, m.serr)
	if m.rspta then
		m.timeout = 0
		m.cli:send(string.char(6))
		local parity = m.rspta:sub(-1)
		local msg = m.rspta:sub(2,-2)
		if parityBit(msg) == parity then
			_, _, r.code, r.sensor = msg:find("(.)(.)%d%d%d%d%d%d%d%d")
			if r.code == "A" then
				_, _, r.code, r.sensor, r.month, r.day, r.hour, r.min, r.molId = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d)")
				if r.code
				and r.sensor
				and r.month
				and r.day
				and r.hour
				and r.min
				and r.molId
				then
					r.status = true
--					print(r.code, r.sensor, r.month, r.day, r.hour, r.min, r.molId)
				else
					_, _, r.code, r.sensor, r.fecha, r.hora, r.secuencia,r.molId = msg:find("(.)(.)(..).(..).(%d%d)(%d%d%d%d%d)")
					if r.code
					and r.sensor
					and r.fecha
					and r.hora
					and r.secuencia
					and r.molId
					then
						r.status = true
						r.month = m.time.month
						r.day = m.time.day
						r.hour = m.time.hour
						r.min = m.time.min
--						print(r.code, r.sensor, r.fecha, r.hora, r.secuencia,r.molId)
--						print(r.code, r.sensor, r.month, r.day, r.hour, r.min, r.lolId)
--[[
						print("\t--------------",int32Tonum(r.fecha),sint32Tonum(r.fecha))
						for i=1, 2 do
							local d = r.fecha:sub(i,i)
							print("\t",string.byte(d),d)
						end
						local rslt = ""
						for b in string.gfind(r.fecha, ".") do
							rslt = rslt .. string.format("%02X", string.byte(b))
						end
						print("hex2dec",string.hex2dec(rslt))
						print("")
						print("\t--------------",int32Tonum(r.hora),sint32Tonum(r.hora))
						for i=1, 2 do
							local d = r.hora:sub(i,i)
							print("\t",string.byte(d),string.byte(d,h8),d)
						end
						print("\t--------------")
						rslt = ""
						for b in string.gfind(r.hora, ".") do
							rslt = rslt .. string.format("%02X", string.byte(b))
						end
						print("hex2dec",string.hex2dec(rslt))
						print("")
						print(int32Tonum(r.fecha..r.hora))
						print(sint32Tonum(r.fecha..r.hora))
						print(socket.gettime())
]]
					end
				end
			elseif r.code == "B" then
				_, _, r.code, r.sensor, r.month, r.day, r.hour, r.min, r.cnt = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d)")
				if r.code
				and r.sensor
				and r.month
				and r.day
				and r.hour
				and r.min
				and r.cnt
				then
					r.status = true
					r.cnt = tonumber(r.cnt)
--				print(r.code, r.sensor, r.month, r.day, r.hour, r.min, tonumber(r.cnt))
				end
			elseif r.code == "2" then
				_, _, r.code, r.sensor, r.month, r.day, r.hour, r.min, r.trj, r.molId, r.secuencia = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d%d%d%d%d%d)(%d%d%d%d%d)(%d%d)")
				if r.code
				and r.sensor
				and r.month
				and r.day
				and r.hour
				and r.min
				and r.trj
				and r.molId
				and r.secuencia
				then
					r.status = true
					r.secuencia = tonumber(r.secuencia)
					r.trj = tonumber(r.trj)
--					print(r.code, r.sensor, r.mm, r.dd, r.hh, r.mn, r.trj, r.molId, r.secuencia)
				else
					_, _, r.code, r.sensor, r.month, r.day, r.hour, r.min, r.trj = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d%d%d%d%d%d)")
					if r.code
					and r.sensor
					and r.month
					and r.day
					and r.hour
					and r.min
					and r.trj
					then
						r.status = true
						r.trj = tonumber(r.trj)
					end
--					print(r.code, r.sensor, r.month, r.day, r.hour, r.min, r.trj)
				end
			else
--				print("No Implementado ", msg)
--				for i=1, msg:len() do
--					print(string.byte(msg:sub(i,i)),msg:sub(i,i))
--				end
--				io.read(1)
			end
		else
			r.error = m.name.." Bad Message "..m.serie
			r.msg = m.rspta
		end
	else
		m.timeout = m.timeout + 1
	end
	if r.month then r.month = tonumber(r.month) end
	if r.day then r.day = tonumber(r.day) end
	if r.hour then r.hour = tonumber(r.hour) end
	if r.min then r.min = tonumber(r.min) end
	return r
end

function setdate(m)
--	print("SetDate()")
	local mymsg = sendmsg(string.format("S%s1%02d%02d%02d%d%02d%02d%02d",m.serie,string.sub(m.time.year,-2), m.time.month, m.time.day, m.time.wday, m.time.hour, m.time.min, m.time.sec))
	m.cli:send(mymsg)
	m.rspta, m.serr = m.cli:receive()
	m.cli:send(string.char(6))
	socket.sleep(1)
--[[
	print("FECHA SETEADA AHORA ESPERA PARA QUE EL MOLINETE ACTUALICE LA MISMA")
	socket.sleep(1)
	local mymsg = sendmsg("S"..m.serie.."A")
	m.cli:send(mymsg)
	m.rspta, m.serr = m.cli:receive()
	return decodeMsg(m)
]]
end

function checkHora(m)
	local mymsg = sendmsg("S"..m.serie.."A")
	m.cli:send(mymsg)
	m.rspta, m.serr = m.cli:receive()
	m.time = os.date("*t", socket.gettime())
	m.time.wday = m.time.wday - 1
	t = decodeMsg(m)
	if t.status then
		if not (t.hour == m.time.hour
		and t.min == m.time.min
		and t.month == m.time.month
		and t.day == m.time.day) 
		then
			t.hour = m.time.hour
			t.min = m.time.min
			t.month = m.time.month
			t.day = m.time.day
			setdate(m)
		end
--		print(string.format("\tFecha:\t%d-%02d-%02d  Hora:\t%02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, t.sec))
		checkFichadas(m)
	else
		if m.serr then
			print(string.format("\tFecha/Hora %s %s (%d)", m.serr, m.name, m.timeout))
		end
--		if t.error then 
--			print(t.error)
--			print(t.msg)
--		end
	end
end
	
function checkFichadas(m)
--	print("CheckFichadas()")
	local mymsg = sendmsg("S"..m.serie.."B")
	m.cli:send(mymsg)
	m.rspta, m.serr = m.cli:receive()
	t = decodeMsg(m)
	if t.status and t.cnt then
--		print(string.format("\tFichadas: %s", t.cnt))
		if t.cnt > 0 then
			getRegistracioes(m)
		end
	else
--		print(m.rspta, m.serr)
--		for k, v in pairs(t) do
--			print(k, v)
--		end
--		if m.serr == nil then
--			io.read(1)
--		end
	end
end

	local es = {}
	es["0"] = "Entra"
	es["1"] = "Sale"
	es["2"] = "Sale-Buzon"
	es["3"] = "Leyo Entrada pero no Entro"
	es["4"] = "Leyo Salida pero no Salio"
	es["5"] = "Leyo Buzon pero no Devolvio"
set = newset()
local tbMol = tbMolinetes()
local conReg = openMy()
local skt, b = socket.connect("172.17.0.56", "8181")
if skt == nil then 
	print(b) 
	os.exit(0)
end
function doSql(dbCon,str)
--	print(str)
	local rslt, serr = dbCon:execute(str)
	if serr then
		print(serr)
		return false
	end
	return true
end

function makeData (msg)
		local searchTrj = string.format([[SELECT * FROM `molinetes`.`trj_mov` where tarjeta='%s' ORDER By idtrj_mov DESC LIMIT 1]],msg.tarjeta)
		local cur, serr = conReg:execute(searchTrj)
		if serr then 
			msg.type="Error"
			msg.data = serr.." - ".. searchTrj
			skt:send(json.encode(msg).."\n")
			return
		end
		if cur:numrows() == 1 then
			row = cur:fetch ({}, "a")
			if row.tipo == "ASIGNA" then
				msg.asignada=row.fecha
				msg.persona=row.a
				cur:close()
				local searchPrs = string.format([[SELECT * FROM `molinetes`.`personas` WHERE id='%s']],msg.persona)
				cur, serr = conReg:execute(searchPrs)
				if serr then
					return
				end
				row = cur:fetch ({}, "a")
				msg.name = row.apellidos.." "..row.nombres
				msg.valid = true
				msg.type = "pasa"
				msg.progId = arg[0]
				msg.secTime = socket.gettime()
				print(json.encode(msg))
				skt:send(json.encode(msg).."\n")
			end
		end
end

function saveData(m,t)
	local fecha = string.format("%d-%02d-%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, 0)
	local sql = string.format([[SELECT * FROM ctrls_mov WHERE fecha='%s' AND idctrl='%s' AND sensor='%s' AND tarjeta='%s']], fecha, m.numero, t.sensor, t.trj)
	local cur = getCur(conReg, sql)
	if cur == nil then return false end
	if cur:numrows() == 0 then
		local sql = string.format(
[[
SELECT CAST(A.Tarjeta AS VARCHAR(36)) AS Tarjeta, CAST(A.Ciudadano AS VARCHAR(36)) AS Ciudadano, Ciudadanos.Apellido, Ciudadanos.Nombre FROM 
(
	select personal.Ciudadano, personal.Tarjeta from personal 
		left join ciudadanos ON ciudadanos.Id = personal.Ciudadano 
		where personal.Tarjeta=(SELECT Id FROM Tarjetas WHERE Numero='%s')
	union
	select Personal.Ciudadano, TarjetasTemporales.Tarjeta
	FROM TarjetasTemporales 
	LEFT JOIN Personal ON 
		Personal.Id = TarjetasTemporales.Personal
	WHERE TarjetasTemporales.Tarjeta = (SELECT Id FROM Tarjetas WHERE Numero='%s')
	AND TarjetasTemporales.Baja is null
	AND TarjetasTemporales.Alta = (
			  select Max(TarjetasTemporales.Alta)
			  from TarjetasTemporales 
			  where TarjetasTemporales.Tarjeta = (SELECT Id FROM Tarjetas WHERE Numero='%s')
			  AND TarjetasTemporales.Alta <= CONVERT(datetime,'%s', 102)
			)
	union 
	select Visitantes.Ciudadano, Visitantes_Tarjetas.Tarjeta 
	FROM Visitantes_Tarjetas 
	LEFT JOIN Visitantes ON 
		Visitantes.Id = Visitantes_Tarjetas.Visitante
	WHERE Visitantes_Tarjetas.Tarjeta = (SELECT Id FROM Tarjetas WHERE Numero='%s')
	AND Visitantes_Tarjetas.Alta <= CONVERT(datetime,'%s', 102)
	AND Visitantes_Tarjetas.Baja is null
) AS A LEFT JOIN Ciudadanos ON A.Ciudadano = Ciudadanos.Id
]], t.trj, t.trj, t.trj, fecha, t.trj, fecha)
		local cur, serr = dbMol:execute(sql)
		if serr then 
			print(serr) 
		else
			local row, serr = cur:fetch({},"a")
			while row do
				print(fecha, row.Apellido.." "..row.Nombre, es[t.sensor] )
				row, serr = cur:fetch({},"a")
			end
		end
		
		local msg = {}
		msg.tarjeta = t.trj
		msg.time = os.time({year = t.year, month = t.month, day = t.day, hour = t.hour, min = t.min, sec = 0})
		msg.lectorname = es[t.sensor]
		msg.molineteId = m.name
		makeData(msg)
		
		local sql = string.format([[INSERT INTO ctrls_mov (fecha, idctrl, sensor, tarjeta) VALUES ('%s', '%s', '%s', '%s')]], fecha, m.numero, t.sensor, t.trj)
		
		return doSql(conReg, sql)
	else
		return true
	end
end

function getRegistracioes(m)
	local mymsg = sendmsg("S"..m.serie.."XB")
	m.cli:send(mymsg)
	m.rspta, m.serr = m.cli:receive()
--	print("\tRegistraciones",m.rspta, m.serr)
	if m.serr == nil then 
		t = decodeMsg(m)
		if t.status and t.secuencia then
			local fecha = string.format("%d-%02d-%02d %02d:%02d:%02d", t.year, t.month, t.day, t.hour, t.min, 0)
--			print("",fecha, t.trj, es[t.sensor])
		end
		while t.secuencia and t.status do
			if saveData(m,t) == true then
				local mymsg = sendmsg(string.format("S%05dXK%02d",m.serie,t.secuencia))
				m.cli:send(mymsg)
				m.rspta, m.serr = m.cli:receive()
				t = decodeMsg(m)
			else
				t.status = nil
				t.secuencia = nil
			end
		end
	end
end

--[[
function msg2_format(msg)
	local f = {}
	f.fecha = msg:sub(4,11)
	f.tarjeta = msg:sub(12,21)
	f.serie = tonumber(msg:sub(22,26))
	f.secuencia = msg:sub(27,28)
	return f
end
]]

	while 1 do
		for n, m in pairs(tbMol) do
			m.now = socket.gettime()
			m.cli = socket.udp()
			m.cli:settimeout(2,"t")
			m.cli:setpeername(m.host, m.port)
--			print(m.host, m.port, m.serie, m.name)
			checkHora(m)
--			checkFichadas(m)
--			print("")
--[[
			if m.cnt > 0 then
				getRegistracioes(m)
			end
]]
			m.cli:close()
		end
--		print("----------------------------------------------")
--		socket.sleep(5)
	end
