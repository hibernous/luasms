require ("utils.cgi_env")
require ("addon.string")
charset = "UTF-8"
charset = "iso-8859-1"
io.write("Content-Type: text/html; charset="..charset.."\r\n")
io.write("Cache-Control: no-store, no-cache, must-revalidate\r\n")
--io.write("Content-Type: text/text\r\n")
io.write("Status: 200\r\n")
--local lendata = string.len(data)
--io.write("Content-Length: "..lendata.."\r\n")
io.write("\r\n")

function toISO (s)
  if string.find(s, "[\224-\255]") then error("non-ISO char") end
  s = string.gsub(s, "([\192-\223])(.)", function (c1, c2)
        c1 = string.byte(c1) - 192
        c2 = string.byte(c2) - 128
        return string.char(c1 * 64 + c2)
      end)
  return s
end

for k, v in pairs(__FORM) do
	print(k,v,"<br>")
end

for i=0, 255 do
	print(i,string.char(i),string.dec2hex(i),"<br>")
end