require ("utils.cgi_env")
require ("db.Class")

require "luasql.mysql"
json = require("json")
mysql = luasql.mysql()
--connMy, serr = mysql:connect("molinetes","root", "pirulo","localhost")
connMy, serr = mysql:connect("molinetes","root", "pirulo","172.17.0.56")

function addslashes(s)
  s = string.gsub(s, "(['\"\\])", "\\%1")
  return (string.gsub(s, "%z", "\\0"))
end
fd = [[
idregistros      int(10) unsigned
fecha            datetime
operator         int(10) unsigned
controler        int(10) unsigned
tpmov            varchar(1)
tarjeta          int(10) unsigned
persona          int(10) unsigned
organismo        varchar(256)
oficina          varchar(256)
ofi_fecha        timestamp
estado           varchar(16)
prs_id           int(10) unsigned
prs_apellidos    char(32)
prs_nombres      char(32)
prs_tpdoc        smallint(5) unsigned
prs_nrodoc       char(20)
prs_sexo         char(1)
]]

tfn = {
	"reg_id",
--	"fecha",
	"reg_operador",
	"reg_controler",
	"reg_tpmov",
	"reg_tarjeta",
	"prs_id",
	"prs_apellidos",
	"prs_nombres",
	"prs_fullname",
	"prs_tpdoc",
	"prs_nrodoc",
	"prs_nacio",
	"prs_sexo",
	"org_id",
	"org_name",
	"ofi_id",
	"ofi_name"
}
local utf8 = {}
utf8["00"] = " "
utf8["01"] = " "
utf8["02"] = " "
utf8["03"] = " "
utf8["04"] = " "
utf8["05"] = " "
utf8["06"] = " "
utf8["07"] = " "
utf8["08"] = " "
utf8["09"] = " "
utf8["0a"] = " "
utf8["0b"] = " "
utf8["0c"] = " "
utf8["0d"] = " "
utf8["0e"] = " "
utf8["0f"] = " "
utf8["10"] = " "
utf8["11"] = " "
utf8["12"] = " "
utf8["13"] = " "
utf8["14"] = " "
utf8["15"] = " "
utf8["16"] = " "
utf8["17"] = " "
utf8["18"] = " "
utf8["19"] = " "
utf8["1a"] = " "
utf8["1b"] = " "
utf8["1c"] = " "
utf8["1d"] = " "
utf8["1e"] = " "
utf8["1f"] = " "
utf8["20"] = " "
utf8["21"] = "!"
utf8["22"] = '"'
utf8["23"] = "#"
utf8["24"] = "$"
utf8["25"] = "%"
utf8["26"] = "&"
utf8["27"] = "'"
utf8["28"] = "("
utf8["29"] = ")"
utf8["2a"] = "*"
utf8["2b"] = "+"
utf8["2c"] = ","
utf8["2e"] = "."
utf8["2f"] = "/"
utf8["30"] = "0"
utf8["31"] = "1"
utf8["32"] = "2"
utf8["33"] = "3"
utf8["34"] = "4"
utf8["35"] = "5"
utf8["36"] = "6"
utf8["37"] = "7"
utf8["38"] = "8"
utf8["39"] = "9"
utf8["3a"] = ":"
utf8["3b"] = ";"
utf8["3c"] = "<"
utf8["3d"] = "="
utf8["3e"] = ">"
utf8["3f"] = "?"
utf8["40"] = "@"
utf8["41"] = "A"
utf8["42"] = "B"
utf8["43"] = "C"
utf8["44"] = "D"
utf8["45"] = "E"
utf8["46"] = "F"
utf8["47"] = "G"
utf8["48"] = "H"
utf8["49"] = "I"
utf8["4a"] = "J"
utf8["4b"] = "K"
utf8["4c"] = "L"
utf8["4d"] = "M"
utf8["4e"] = "N"
utf8["4f"] = "O"
utf8["50"] = "P"
utf8["51"] = "Q"
utf8["52"] = "R"
utf8["53"] = "S"
utf8["54"] = "T"
utf8["55"] = "U"
utf8["56"] = "V"
utf8["57"] = "W"
utf8["58"] = "X"
utf8["59"] = "Y"
utf8["5a"] = "Z"
utf8["5b"] = "["
utf8["5c"] = "\\"
utf8["5d"] = "]"
utf8["5e"] = "^"
utf8["5f"] = "_"
utf8["60"] = "`"
utf8["61"] = "a"
utf8["62"] = "b"
utf8["63"] = "c"
utf8["64"] = "d"
utf8["65"] = "e"
utf8["66"] = "f"
utf8["67"] = "g"
utf8["68"] = "h"
utf8["69"] = "i"
utf8["6a"] = "j"
utf8["6b"] = "k"
utf8["6c"] = "l"
utf8["6d"] = "m"
utf8["6e"] = "n"
utf8["6f"] = "o"
utf8["70"] = "p"
utf8["71"] = "q"
utf8["72"] = "r"
utf8["73"] = "s"
utf8["74"] = "t"
utf8["75"] = "u"
utf8["76"] = "v"
utf8["77"] = "w"
utf8["78"] = "x"
utf8["79"] = "y"
utf8["7a"] = "z"
utf8["7b"] = "{"
utf8["7c"] = "|"
utf8["7d"] = "}"
utf8["7e"] = "~"
utf8["7f"] = " "
utf8["c280"] = " "  
utf8["c281"] = " "
utf8["c282"] = " "
utf8["c283"] = " "
utf8["c284"] = " "
utf8["c285"] = " "
utf8["c286"] = " "
utf8["c287"] = " "
utf8["c288"] = " "
utf8["c289"] = " "
utf8["c28a"] = " "
utf8["c28b"] = " "
utf8["c28c"] = " "
utf8["c28d"] = " "
utf8["c28e"] = " "
utf8["c28f"] = " "
utf8["c290"] = " "
utf8["c291"] = " "
utf8["c292"] = " "
utf8["c293"] = " "
utf8["c294"] = " "
utf8["c295"] = " "
utf8["c296"] = " "
utf8["c298"] = " "
utf8["c299"] = " "
utf8["c29a"] = " "
utf8["c29b"] = " "
utf8["c29c"] = " "
utf8["c29d"] = " "
utf8["c29e"] = " "
utf8["c29f"] = " "
utf8["c2a0"] = " "
utf8["c2a1"] = "¡"
utf8["c2a2"] = "¢"
utf8["c2a3"] = "£"
utf8["c2a4"] = "¤"
utf8["c2a5"] = "¥"
utf8["c2a6"] = "¦"
utf8["c2a7"] = "§"
utf8["c2a8"] = "¨"
utf8["c2a9"] = "©"
utf8["c2aa"] = "ª"
utf8["c2ab"] = "«"
utf8["c2ac"] = "¬"
utf8["c2ad"] = "­"
utf8["c2ae"] = "®"
utf8["c2af"] = "¯"
utf8["c2b0"] = "°"
utf8["c2b1"] = "±"
utf8["c2b2"] = "²"
utf8["c2b3"] = "³"
utf8["c2b4"] = "´"
utf8["c2b5"] = "µ"
utf8["c2b6"] = "¶"
utf8["c2b7"] = "·"
utf8["c2b8"] = "¸"
utf8["c2b9"] = "¹"
utf8["c2ba"] = "º"
utf8["c2bb"] = "»"
utf8["c2bc"] = "¼"
utf8["c2bd"] = "½"
utf8["c2be"] = "¾"
utf8["c2bf"] = "¿"
utf8["c380"] = "À"
utf8["c381"] = "Á"
utf8["c382"] = "Â"
utf8["c383"] = "Ã"
utf8["c384"] = "Ä"
utf8["c385"] = "Å"
utf8["c386"] = "Æ"
utf8["c387"] = "Ç"
utf8["c388"] = "È"
utf8["c389"] = "É"
utf8["c38a"] = "Ê"
utf8["c38b"] = "Ë"
utf8["c38c"] = "Ì"
utf8["c38d"] = "Í"
utf8["c38e"] = "Î"
utf8["c38f"] = "Ï"
utf8["c390"] = "Ð"
utf8["c391"] = "Ñ"
utf8["c392"] = "Ò"
utf8["c393"] = "Ó"
utf8["c394"] = "Ô"
utf8["c395"] = "Õ"
utf8["c396"] = "Ö"
utf8["c397"] = "×"
utf8["c398"] = "Ø"
utf8["c399"] = "Ù"
utf8["c39a"] = "Ú"
utf8["c39b"] = "Û"
utf8["c39c"] = "Ü"
utf8["c39d"] = "Ý"
utf8["c39e"] = "Þ"
utf8["c39f"] = "ß"
utf8["c3a0"] = "à"
utf8["c3a1"] = "á"
utf8["c3a2"] = "â"
utf8["c3a3"] = "ã"
utf8["c3a4"] = "ä"
utf8["c3a5"] = "å"
utf8["c3a6"] = "æ"
utf8["c3a7"] = "ç"
utf8["c3a8"] = "è"
utf8["c3a9"] = "é"
utf8["c3aa"] = "ê"
utf8["c3ab"] = "ë"
utf8["c3ac"] = "ì"
utf8["c3ad"] = "í"
utf8["c3ae"] = "î"
utf8["c3af"] = "ï"
utf8["c3b0"] = "ð"
utf8["c3b1"] = "ñ"
utf8["c3b2"] = "ò"
utf8["c3b3"] = "ó"
utf8["c3b4"] = "ô"
utf8["c3b5"] = "õ"
utf8["c3b6"] = "ö"
utf8["c3b7"] = "÷"
utf8["c3b8"] = "ø"
utf8["c3b9"] = "ù"
utf8["c3ba"] = "ú"
utf8["c3bb"] = "û"
utf8["c3bc"] = "ü"
utf8["c3bd"] = "ý"
utf8["c3be"] = "þ"
utf8["c3bf"] = "ÿ"

function decodeUTF8(s)
	s = string.gsub(s, "%%C2%%(%x%x)", function (b)
		b = string.lower(b)
		local h = utf8["c2"..b]
		if h then return h end
		return "C2"..b
	end)
	s = string.gsub(s, "%%c2%%(%x%x)", function (b)
		b = string.lower(b)
		local h = utf8["c2"..b]
		if h then return h end
		return "c2"..b
	end)
	s = string.gsub(s, "%%C3%%(%x%x)", function (b)
		b = string.lower(b)
		local h = utf8["c3"..b]
		if h then return h end
		return "C3"..b
	end)
	s = string.gsub(s, "%%c3%%(%x%x)", function (b)
		b = string.lower(b)
		local h = utf8["c3"..b]
		if h then return h end
		return "c3"..b
	end)
	return s
end		
twhere = {}

for k, v in pairs(__FORM) do
	__FORM[k] = decodeUTF8(v)
end

local fchini = __FORM.fchini or ""
local fchend = __FORM.fchend or ""
--[[
if not (fchini=="" or fchend=="") then
	twhere.fecha = string.format("fecha>='%s' and fecha<='%s'", fchini, fchend)
elseif fchend == "" then
	twhere.fecha = string.format("fecha>='%s'", fchini)
elseif fchini == "" then
	twhere.fecha = string.format("fecha<='%s'", fchend)
end

sqlstr = "WHERE "
sep = ""
for k, v in pairs(twhere) do
	sqlstr = sqlstr..sep..v
	sep = " AND "
end
if sqlstr == "WHERE " then
	sqlstr = ""
end
--local cur, serror = connMS:execute("SELECT Foto FROM Ciudadanos WHERE Id=CAST('"..____FORM.foto.."' AS uniqueidentifier)")
sqlstr = string.format("SELECT * FROM `molinetes`.`es_view` %s order by fecha desc",sqlstr)
local cur, serror = connMy:execute(sqlstr)
if serror then
	print(serror)
	os.exit(0)
end
tdata = {}
tdata.sql = sqlstr
tdata.rows = {}
row = cur:fetch({},"a")
while row do
	tdata.rows[#tdata.rows+1] = row
	row = cur:fetch({},"a")
end
tdata.rowcount = #tdata.rows
]]--

molDBconn = dbClass.new("molinetes","root", "pirulo", "mysql", "172.17.0.56")

tbES = dbtable("reg_view",molDBconn)
--tbES = dbtable(sqlstr,molDBconn)
if fchini ~= "" then
	twhere.reg_fecha = string.format("reg_fecha>='%s'", fchini)
end

if fchend ~= "" then
	twhere.rer_fecha = string.format("reg_fecha<='%s'", fchend)
end

for k, v in ipairs(tfn) do
	if __FORM[v] and __FORM[v] ~= "" then
		if __FORM[v] == "NULL" then
			twhere[v] = string.format("%s IS %s", v, __FORM[v])
		else
			if v == "prs_fullname" then
				twhere[v] = string.format("LEFT(%s,%d)='%s'",v,__FORM[v]:len(),__FORM[v])
			elseif v == "prs_apellidos" then
				twhere[v] = string.format("LEFT(%s,%d)='%s'",v,__FORM[v]:len(),__FORM[v])
			elseif v == "prs_nombres" then
				twhere[v] = string.format("LEFT(%s,%d)='%s'",v,__FORM[v]:len(),__FORM[v])
			else
				twhere[v] = string.format("%s='%s'", v, __FORM[v])
			end
		end
	end
end
sqlstr = ""
sep = ""
for k, v in pairs(twhere) do
	sqlstr = sqlstr..sep..v
	sep = " AND "
end

tbES:setWhere(sqlstr)
tbES:setOrder("reg_fecha desc")
tbES:setLimit(100)
local tdata = tbES:read()
--tdata.rows = nil
--tdata.cols = nil
--tdata.rows = nil
local data = json.encode(tdata)
--io.write("Content-Type: application/x-json; charset=UTF-8\r\n")
--io.write("Content-Type: text/x-json; charset=UTF-8\r\n")
charset = "UTF-8"
--charset = "iso-8859-1"
io.write("Content-Type: text/html; charset="..charset.."\r\n")
io.write("Cache-Control: no-store, no-cache, must-revalidate\r\n")
--io.write("Content-Type: text/text\r\n")
io.write("Status: 200\r\n")
--local lendata = string.len(data)
--io.write("Content-Length: "..lendata.."\r\n")
io.write("\r\n")
io.write(data)
io.write("\r\n")
molDBconn:close()
--cur:close()
--[[
for k, row in ipairs(tdata.rows) do
	print(row.reg_fecha, row.reg_tpmov)
end
]]
os.exit(0)
