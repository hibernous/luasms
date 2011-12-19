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
	bit = "00000000"
	for a in string.gmatch(s, ".", "%1") do
		local c = string.dec2bin(string.byte(a))
		if c:len() == 4 then c = "0000"..c end
		bit = string.binXOr(c,bit)
	end
	return (string.char(string.bin2dec(bit)))
end

function sendmsg(s)
	local stx="" -- string.char(2)
	local etx="" -- string.char(3)
	local msg = stx..s..etx
	msg = msg..parityBit(msg)
	return msg
end

function processMsg(msg, num, cli)
	local r = {}
	_, _, r.code, r.errcod, r.mm, r.dd, r.hh, r.mn = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)")
	if code == "A" then
		_, _, r.code, r.errcod, r.mm, r.dd, r.hh, r.mn, r.molId = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d)")
		print(r.code, r.errcod, r.mm, r.dd, r.hh, r.mn, r.molId)
	elseif code == "B" then
		_, _, r.code, r.errcod, r.mm, r.dd, r.hh, r.mn, r.cnt = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d)")
		print(code, errcod, mm, dd, hh, mn, tonumber(cnt))
	elseif r.code == "2" then
		_, _, r.code, r.sensor, r.mm, r.dd, r.hh, r.mn, r.trj, r.molId, r.secuencia = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d%d%d%d%d%d)(%d%d%d%d%d)(%d%d)")
		if r.code then
			print(r.code, r.sensor, r.mm, r.dd, r.hh, r.mn, r.trj, r.molId, r.secuencia)
		else
			_, _, r.code, r.sensor, r.mm, r.dd, r.hh, r.mn, r.trj = msg:find("(.)(.)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d%d%d%d%d%d%d%d%d)")
			print(r.code, r.sensor, r.mm, r.dd, r.hh, r.mn, r.trj)
		end
	else
		print("No Implementado ", msg)
		return nil
	end
end
		
local socket = require("socket")

--[[
-- change here to the host an port you want to contact
print("Hola")
local host, port = "localhost", 3010
-- load namespace
-- convert host name to ip address
local ip = "192.168.0.11" --socket.try(socket.dns.toip(host))
-- create a new UDP object
local udp = socket.udp()
-- contact daytime host
--S17529X+T10504716700z
print(udp:sendto(sendmsg("SL17537"), ip, port))
-- retrieve the answer and print results
print(udp:receive())
--parityBit("S17531X-T0109262956")

]]
host = host or "192.168.0.11"
port = port or 3010
if arg then
    host = arg[1] or host
    port = arg[2] or port
    num = arg[3] or ""
    cmd = arg[4] or ""
end
--host = socket.dns.toip(host)
cli = socket.udp()
cli:settimeout(3,"t")
print(cli:setpeername(host, port))
local mymsg = sendmsg("S"..num..cmd)
print("Destination Peer: "..cli:getpeername() )
send, serr = cli:send(mymsg)
print("Envio: ",mymsg, send, serr)
local m = ""
--while string.len(m)<5 do
--while true do
	m, serr, e = cli:receive()
	print(m, serr, e)
--end
if serr == nil then 
	send, serr = cli:send(string.char(6))
	local parity = m:sub(-1)
	local msg = m:sub(2,-2)
	print(msg, parity)
	if parity == parityBit(msg) then 
		processMsg(msg,num,cli)
		print("Ok")
	end
end
cli:close()
--print (send, serr)
--[[
if m == string.char(6) then
	cli:close()
	print(string.byte(m))
	cli = socket.udp()
	cli:setpeername(host, port)
	m=nil
	while m==nil do
		m, serr, e = cli:receive(1)
		print(m, serr, e)
	end
	print (m)
end
]]