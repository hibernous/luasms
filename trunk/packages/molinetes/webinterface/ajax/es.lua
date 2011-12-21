require("connectdb")
require("lua.ajaxresponse")
dbid = "reg_id"
dbsel = "*"
dbtable = "es_view"

--conMy, serr = mysql:connect("molinetes","root", "pirulo","10.10.8.6")
if serr then
	print(serr)
end
--[[
if __FORM.oper then
	local sql = ""
	if __FORM.oper == "edit" then
--		sql = string.format("UPDATE %s SET email='%s', descripcion='%s', principal='%s' WHERE %s='%s'", dbtable, __FORM.email, __FORM.descripcion, __FORM.principal, dbid, __FORM.id)
	elseif __FORM.oper == "add" then
--		sql = string.format("INSERT INTO %s (tonumber, msg) VALUES ('%s', '%s')",dbtable, __FORM.tonumber, __FORM.msg)
	elseif __FORM.oper == "del" then
--		sql = string.format("DELETE FROM %s WHERE %s='%s'", dbtable, dbid, __FORM.id)
	end
--	rslt, serr = doSQL(conMy, sql)
	if serr then
		ajax_error(json.encode(serr))
	else
		ajax_response(json.encode("ok"))
	end
	os.exit(0)
end
]]
resp = {}
resp.page = 0
resp.total = 0
resp.records = 0
resp.rows = {}

--fixWhere = string.format("idpersona='%s'",__FORM.idpersona)

resp.records, serr = totalRegs(conMy, dbtable)
--resp.records, serr = totalRegs(conMy, "registros")

if serr == nil then
	resp.page = tonumber(__FORM.page) or 1
	local limit = tonumber(__FORM.rows) or 10
	if resp.records > 0 then
		resp.total = math.ceil(resp.records/limit); 
	else
		resp.total  = 0; 
	end
	if resp.page > resp.total then
		resp.page = resp.total
	end
	if resp.page < 1 then resp.page = 1 end
	start = limit*resp.page - limit;
	debugLog(limit.." ".. resp.page)
	if resp.records > 0 then
		resp.rows = getRows(conMy,dbtable, dbid, dbsel, start, limit)
	else
		resp.roww = {}
	end
end
ajax_responce(json.encode(resp))