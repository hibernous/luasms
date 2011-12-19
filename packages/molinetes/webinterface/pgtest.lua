require "luasql.postgres"
postgres = luasql.postgres()
--connMy, serr = mysql:connect("molinetes","root", "pirulo","localhost")
--connPG, serr = postgres:connect("Siup001","admin", "rvoilcat1","172.17.0.2")
connPG, serr = postgres:connect("siup","admin", "rvoilcat1","172.17.0.2")
--connPG, serr = postgres:connect("sisdev","admin", "admin", "172.17.1.23")
if serr then 
	print(serr)
	os.exit(0)
end
--cur, serr = connPG:execute("SELECT * FROM admin_persona LIMIT 1000 offset 100000")
cur, serr = connPG:execute("SELECT * FROM DesarrolloSocial.padronsi LIMIT 1000 offset 100000")
if serr then
	print(serr)
	os.exit(0)
end
local row = cur:fetch ({}, "a")
while row do
	for k,v in pairs(row) do
		print(k,v)
	end
end