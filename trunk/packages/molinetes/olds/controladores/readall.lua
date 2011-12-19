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
	local connMy, serr = mysql:connect("dbo_molinetes","root", "pirulo", host)
	if not connMy then
		print("Error al conectar con MySql en Host: "..host)
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

function doSql(dbCon,str)
--	print(str)
	local rslt, serr = dbCon:execute(sql)
	if serr then
		print(serr)
		os.exit(0)
	end
end

function doTra(dbCon,str)
--	print(str)
	local rslt, serr = dbCon:execute(sql)
end

function getCur(dbCon, sql)
	local cur, serr = dbCon:execute(sql)
	if serr then 
		print(serr) 
		os.exit(0)
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
	dbMol = openMS("moli")
	sql = "SELECT Descripcion, IP, Serie, Numero FROM Molinetes"
	cur = getCur(dbMol, sql)
	local row = cur:fetch ({}, "a")
	while row do
		local n = row.Serie
		if tonumber(row.Numero) < 7 then
		t[n] 			= {}
		t[n].serie		= row.Serie
		t[n].name		= row.Descripcion
		t[n].host		= row.IP
		t[n].port		= 3001
		t[n].waiting	= 0
		t[n].failopen	= 0
		t[n].reopen		= 0
		t[n].last		= 0
		t[n].msg		= ""
		t[n].cli		= connectMolinete(t[n])
		end
		row = cur:fetch ({}, "a")
	end
	return t
end

set = newset()
local tbMol = tbMolinetes()

function msg2_format(msg)
	local f = {}
	f.fecha = msg:sub(4,11)
	f.tarjeta = msg:sub(12,21)
	f.serie = tonumber(msg:sub(22,26))
	f.secuencia = msg:sub(27,28)
	return f
end

	while 1 do
		for n, m in pairs(tbMol) do
--			print(m.name, m.cli)
			if m.cli then
				local moli = set:data(m.cli)
				if socket.gettime() - moli.waiting >= 30 then
					msgs = sendmsg("S"..n..arg[1])
					print("Envia "..msgs.." a "..m.name)
					l, serr = moli.cli:send(msgs)
					moli.waiting = socket.gettime()
					if serr then
						print(string.format("Error enviando MSG: %s en %s",serr, m.name))
						m.cli = nil
						set:remove(m.cli)
					end
				end
			else
				m.cli = connectMolinete(m)
			end
		end
		print("----------------------------------------------")
		local readable, _, serr = socket.select(set, nil,1)
		if serr then
			print("Select ", serr)
--[[
			if seltimeout == 20 then
				print("cerrar todo")
				for n, m in pairs(tbMol) do
					if m.cli then
						local moli = set:data(m.cli)
						print("Cerrando/Removiendo ", m.name)
						m.waiting = false
						m.cli:close()
						set:remove(m.cli)
						m.cli = nil
					end
				end
				seltimeout = 0
			else
				seltimeout = seltimeout + 1
			end
]]
		else
			seltimeout = 0
		for _, input in ipairs(readable) do
--			print(#readable)
			-- is it a server socket?
			local moli = set:data(input)
--			print(moli.name)
			local ok = false
			while ok == false do
				local c, serr = moli.cli:receive(1)
				if serr == "closed" then
					set:remove(moli.cli)
					print("Remuevo Cli")
					m.cli = connectMolinete(m)
					
				end
				if serr then 
					print(moli.name, serr)
					break
				end
--				print("primer read",moli.name,c,serr)
				if c == string.char(6) then
					moli.msg = ""
					moli.em = false
					moli.waiting = socket.gettime()
					moli.last = socket.gettime()
--					readMessage(moli)
				else
					if c then
						moli.waiting = socket.gettime()
						moli.last = socket.gettime()
						if moli.em == true then
--							print(c, parityBit(moli.msg))
							if c == parityBit(moli.msg) then
								ok = true
								break
							end
						end
						if string.byte(c) == 3 then
							moli.em = true
						end
						moli.msg = moli.msg..c
--							print(moli.name, c, moli.msg)
					else
						if serr == "timeout" then
							break
						end
						print("recibiendo ",serr)
					end
				end
			end

			if ok == true then
				msgs = sendmsg("S"..moli.serie.."A")
				moli.cli:send(msgs)
				print("Completo : ", moli.name, moli.msg)
				moli.waiting = 0
			else 
				print("Parcial ", moli.name, moli.msg)
			end
		end
		print("----------------------------------------------")
		socket.sleep(2)
		end
	end
