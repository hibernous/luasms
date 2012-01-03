require("lua.ajaxresponse")
require("connectdb")
strSQL = string.format([[SELECT nrodoc AS matricula
		, CONCAT(apellidos,' ',nombres) AS name
		, apellidos AS apellidos
		, nombres AS nombres
		, id AS id
		, `molinetes`.`get_prsorgofi`(id) AS orgofi
		, `molinetes`.`get_prstrj`(id,'ASIGNA') AS tarjeta
		FROM personas WHERE nrodoc LIKE '%s%%' or CONCAT(apellidos,' ',nombres) LIKE '%s%%'
		order by apellidos, nombres
]],__FORM.term, __FORM.term)
local rows = {}
local cur, serr = conMy:execute(strSQL)
local matriculas = {}
local mylist = ""
local sep = ""
if cur then
	local row = cur:fetch({},"a")
	while row do
		rows[#rows+1] = {value=row.matricula, label=row.name, id=row.id, apellidos=row.apellidos, nombres=row.nombres, orgofi=row.orgofi, tarjeta=row.tarjeta, base='i'}
		matriculas[row.matricula] = #rows
		mylist = string.format("%s%s'%s'",mylist,sep,row.matricula)
		sep=","
		row = cur:fetch({},"a")
	end
--	ajax_responce(json.encode(rows))
end
cur:close()
strSQL = string.format([[SELECT *
		FROM `votos`.`padron_caro` 
		WHERE matricula LIKE '%s%%' or apeynom LIKE '%s%%' or matricula in (%s) order by apeynom limit 50
	]],__FORM.term, __FORM.term, mylist)
local cur, serr = conMy:execute(strSQL)
if cur then
	local row = cur:fetch({},"a")
	while row do
		if matriculas[row.matricula] then
			rows[matriculas[row.matricula]].base		= "b"
			rows[matriculas[row.matricula]].clase		= row.clase
			rows[matriculas[row.matricula]].departamento= row.departamento
			rows[matriculas[row.matricula]].localidad	= row.localidad
			rows[matriculas[row.matricula]].sexo		= row.sexo
			rows[matriculas[row.matricula]].domicilio	= row.domicilio
			rows[matriculas[row.matricula]].apeynom		= row.apeynom
		else
			rows[#rows+1] = row
			rows[#rows].base = 'p'
			rows[#rows].value = row.matricula
			rows[#rows].label = row.apeynom
			rows[#rows].matricula = nil
		end
		row = cur:fetch({},"a")
	end
	ajax_responce(json.encode(rows))
else
	ajax_responce(json.encode({error=serr}))
end
cur:close()
conMy:close()
