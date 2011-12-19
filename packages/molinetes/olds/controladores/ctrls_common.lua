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
--	s	-> binary string
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

function trim (str)
	if str == nil then return "" end
	return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

function fixNames(str)
	if str == nil then return "" end
	local str = str:lower()
	t = {}
	for name in string.gmatch(str,"%S+") do
		t[#t+1]= name:gsub("%a", string.upper, 1)
	end
	str = ""
	for i=1, #t do
		str = str..t[i].." "
	end
	str = trim(str)
	str = addslashes(str)
	return str
end

function addslashes(s)
  if s == nil then return s end
  s = string.gsub(s, "(['\"\\])", "\\%1")
  return (string.gsub(s, "%z", "\\0"))
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

function printD(...)
	local lista = {...}
	if DEBUG then
		print(unpack(lista))
	end
end

function errorLevel(m,strerr)
	local level = 0
	if m.fail[m.f] > 9 then
		if (m.fail[m.f] % 10) == 0 then
--			printDL(2,strerr)
			level = 2
		end
	elseif m.fail[m.f] > 4 then
		if (m.fail[m.f] % 5) == 0 then
--			printDL(3,strerr)
			level = 3
		end
	else
--		printDL(4,strerr)
		level = 4
	end
	return level, strerr
end

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

function doSql(dbCon,str)
	local rslt, serr = nil, nil
	if dbConStatus(dbCon) then
		printDL(8,str)
		rslt, serr = dbCon:execute(str)
		if serr then
			printDL(2,string.format("\n\n----------------------------------------------------------\ndoSql:'%s'", serr))
--			io.read(1)
--			printDL(2,string.format("\n\n\ndoSql:'%s'", serr))
			printDL(2,string.format("\n\nStatement:\n\n'%s'-----------------------------------------------------------", str)) 
--			io.read(1)
			if serr:match("Error en el vínculo de comunicación") 
			or serr:match("MySQL server has gone away")
			then
				dbCon:close()
			end
		end
	end
	return rslt, serr
end

