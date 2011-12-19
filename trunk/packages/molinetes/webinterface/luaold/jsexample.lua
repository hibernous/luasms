require ("utils.cgi_env")
require "luasql.mysql"
json = require("json")
mysql = luasql.mysql()
--connMy, serr = mysql:connect("molinetes","root", "pirulo","localhost")
connMy, serr = mysql:connect("molinetes","root", "pirulo","172.17.0.56")
--[[
// Include the information needed for the connection to
// MySQL data base server. 
include("dbconfig.php");
//since we want to use a JSON data we should include
//encoder and decoder for JSON notation
//If you use a php >= 5 this file is not needed
//include("JSON.php");

// create a JSON service
//$json = new Services_JSON();

// to the url parameter are added 4 parameter
// we shuld get these parameter to construct the needed query
// for the pager

// get the requested page
$page = $_REQUEST['page'];
]]
page = tonumber(__FORM.page) or 0
--[[
// get how many rows we want to have into the grid
// rowNum parameter in the grid
$limit = $_REQUEST['rows'];
]]
limit = tonumber(__FORM.limit) or 0
--[[
// get index row - i.e. user click to sort
// at first time sortname parameter - after that the index from colModel
$sidx = $_REQUEST['sidx'];
]]
sidx = tonumber(__FORM.sidx) or 1
--// sorting order - at first time sortorder
--$sord = $_REQUEST['sord']; 
sord = __FORM.sord
--// if we not pass at first time index use the first column for the index
--if(!$sidx) $sidx =1;
if not sidx then sidx = 1 end
--[[
// connect to the MySQL database server
$db = mysql_connect($dbhost, $dbuser, $dbpassword)
or die("Connection Error: " . mysql_error());

// select the database
mysql_select_db($database) or die("Error conecting to db.");

// calculate the number of rows for the query. We need this to paging the result
$result = mysql_query("SELECT COUNT(*) AS count FROM invheader a, clients b WHERE a.client_id=b.client_id");
$row = mysql_fetch_array($result,MYSQL_ASSOC);
$count = $row['count'];
]]

sqlstr = string.format([[SELECT COUNT(*) AS count FROM `molinetes`.`registros`]])
print (sqlstr)
local cur, serror = connMy:execute(sqlstr)
count = tonumber(cur:fetch())
print(count)
--[[
// calculation of total pages for the query
if( $count >0 ) {
	$total_pages = ceil($count/$limit);
} else {
	$total_pages = 0;
}
]]
if count > 0 then
	total_pages = math.ceil(count/limit)
else
	total_pages = 0
end
--[[
// if for some reasons the requested page is greater than the total
// set the requested page to total page
if ($page > $total_pages) $page=$total_pages;
]]
if page > total_pages then page = total_pages end
--[[
// calculate the starting position of the rows
$start = $limit*$page - $limit; // do not put $limit*($page - 1)
]]
start = limit*page - limit
--[[
// if for some reasons start position is negative set it to 0
// typical case is that the user type 0 for the requested page
if($start <0) $start = 0;
]]
if start < 0 then start = 0 end 
--[[
// the actual query for the grid data
$SQL = "SELECT a.id, a.invdate, b.name, a.amount,a.tax,a.total,a.note FROM invheader a, clients b WHERE a.client_id=b.client_id ORDER BY $sidx $sord LIMIT $start , $limit";
$result = mysql_query( $SQL ) or die("Couldn t execute query.".mysql_error());

// constructing a JSON
$responce->page = $page;
$responce->total = $total_pages;
$responce->records = $count;
$i=0;
while($row = mysql_fetch_array($result,MYSQL_ASSOC)) {
    $responce->rows[$i]['id']=$row[id];
    $responce->rows[$i]['cell']=array($row[id],$row[invdate],$row[name],$row[amount],$row[tax],$row[total],$row[note]);
    $i++;
}
// return the formated data
//echo $json->encode($responce);
echo json_encode($responce);
]]
sqlstr = string.format([[SELECT * FROM `molinetes`.`es_view` WHERE ofi_id='56' order by fecha desc LIMIT %s, %s]], start, limit)
local cur, serror = connMy:execute(sqlstr)
if serror then
	print(serror)
	os.exit(0)
end
tdata = {}
tdata.page = page
tdata.total = total_pages
tdata.records = count
tdata.rows = {}
i  = 0
row = cur:fetch({},"a")
while row do
	print(row.idregistros)
	tdata.rows[#tdata.rows+1] = {}	
	tdata.rows[#tdata.rows].idregistros = row.idregistros
	tdata.rows[#tdata.rows].cell = {row.idregistros, row.fecha, row.tarjeta, row.persona, row.prs_apellidos, row.prs_nombres}
--[[
	        {name:'idregistros',index:'idregistros', width:55},
        {name:'fecha',index:'fecha', width:90},
    	{name:'tarjeta',index:'name asc, invdate', width:100},
        {name:'persona',index:'amount', width:80, align:"right"},
        {name:'prs_apellidos',index:'prs_apellidos', width:80, align:"right"},		
        {name:'prs_nombres',index:'prs_nombres', width:80,align:"right"}		

	for k, v in pairs(row) do
		table.insert(tdata.rows[#tdata.rows].cell,v)
--		tdata.rows[#tdata.rows].cell[k] = v
	end
]]
	row = cur:fetch({},"a")
end
cur:close()
connMy:close()
local data  = json.encode(tdata)
--io.write("Content-Type: application/x-json\r\n")
--io.write("Content-Type: text/x-json\r\n")
--io.write("Content-Type: text/html\r\n")
--io.write("Status: 200\r\n")
--io.write("Content-Length: "..string.len(data).."\r\n")
--io.write("\r\n")
io.write(data)
io.write("\r\n")
os.exit(0)

	