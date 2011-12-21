require("lua.ajaxresponse")
require("connectdb")
strSQL = string.format([[SELECT nrodoc AS matricula
		, CONCAT(apellidos,' ',nombres) AS name 
		FROM personas WHERE nrodoc LIKE '%s%%' or CONCAT(apellidos,' ',nombres) LIKE '%s%%'
		order by apellidos, nombres
]],__FORM.term, __FORM.term)
local rows = {}
local cur, serr = conMy:execute(strSQL)
if cur then
	local row = cur:fetch({},"a")
	while row do
		rows[#rows+1] = {value=row.matricula, label=row.name}
		row = cur:fetch({},"a")
	end
--	ajax_responce(json.encode(rows))
end
cur:close()
strSQL = string.format([[SELECT matricula AS matricula
		, apeynom AS name
		FROM `votos`.`padron_caro` 
		WHERE matricula LIKE '%s%%' or apeynom LIKE '%s%%' order by apeynom
	]],__FORM.term, __FORM.term)
local cur, serr = conMy:execute(strSQL)
if cur then
	local row = cur:fetch({},"a")
	while row do
		rows[#rows+1] = {value=row.matricula, label=row.name}
		row = cur:fetch({},"a")
	end
	ajax_responce(json.encode(rows))
else
	ajax_responce(json.encode({error=serr}))
end
cur:close()
conMy:close()
