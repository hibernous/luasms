require ("utils.cgi_env")
require ("db.Class")
json = require("json")
molDBconn = dbClass.new("molinetes","root", "pirulo", "mysql", "172.17.0.56")
tbOfi = dbtable("oficinas",molDBconn)
tbOfi:setWhere(string.format("idorganismo='%s'",__FORM["id"]))
tbOfi:setOrder("name")
tbOfi:setLimit(0)
local tdata = tbOfi:read()
molDBconn:close()
local data = json.encode(tdata)
io.write("Content-Type: text/html\r\n")
io.write("Status: 200\r\n")
io.write("Content-Length: "..string.len(data).."\r\n")
io.write("\r\n")
io.write(data)
io.write("\r\n")
os.exit(0)
