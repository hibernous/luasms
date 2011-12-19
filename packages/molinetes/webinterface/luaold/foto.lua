require ("utils.cgi_env")
require "luasql.mysql"
mysql = luasql.mysql()
--connMy, serr = mysql:connect("molinetes","root", "pirulo","localhost")
connMy, serr = mysql:connect("molinetes","root", "pirulo","172.17.0.56")

function addslashes(s)
  s = string.gsub(s, "(['\"\\])", "\\%1")
  return (string.gsub(s, "%z", "\\0"))
end

--local cur, serror = connMS:execute("SELECT Foto FROM Ciudadanos WHERE Id=CAST('"..__FORM.foto.."' AS uniqueidentifier)")
local cur, serror = connMy:execute("SELECT data FROM fotos WHERE id='"..__FORM.foto.."'")
if serror then
	print(serror)
	os.exit(0)
end

local data = cur:fetch()
if data == nil then
	f = io.open("/var/www/molinetes/images/no_photo.png","r")
--	f = io.open("/var/www/molinetes/images/smile.jpg","r")
	data = f:read("*all")
	f:close()
end
	
io.write("Content-Type: image/jpeg\r\n")
io.write("Status: 200\r\n")
io.write("Content-Length: "..string.len(data).."\r\n")
io.write("\r\n")
io.write(data)
io.write("\r\n")
cur:close()
connMS:close()
os.exit(0)
