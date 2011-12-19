local function i_div(a,b)
	local c = (a % b)
	a = a-(a %b)
	return a/b
end

local function calcPages(a, b)
	if a == 0 then return 0 end
	if b == 0 then return 1 end
	local c = (a % b)
	if c == 0 then 
		return a/b
	else 
		return ((a-c)/b)+1 
	end
end

local function parseSelect(p)
	local str = ""
	if p then
		if type(p) == "string" then 
			str = p
		end
	else
		str = "*"
	end
	str = string.gsub(str, "^%s*(.-)%s*$", "%1")
	if str ~= "" then
		str = "SELECT "..str
	end
	return str
end
	
local function parseFrom(p)
	local str = ""
	if p then
		if type(p) == "string" then 
			str = p
		end
	end
	str = string.gsub(str, "^%s*(.-)%s*$", "%1")
	if str ~= "" then
		str = " FROM "..str
	end
	return str
end
	
local function parseWhere(p)
	local str = ""
	if p then
		if type(p) == "string" then 
			str = p
		end
	end
	str = string.gsub(str, "^%s*(.-)%s*$", "%1")
	if str ~= "" then
		str = " WHERE "..str
	end
	return str
end
	
local function parseGroup(p)
	local str = ""
	if p then
		if type(p) == "string" then 
			str = p
		end
	end
	str = string.gsub(str, "^%s*(.-)%s*$", "%1")
	if str ~= "" then
		str = " GROUP BY "..str
	end
	return str
end

local function parseHaving(p)
	local str = ""
	if p then
		if type(p) == "string" then 
			str = p
		end
	end
	str = string.gsub(str, "^%s*(.-)%s*$", "%1")
	if str ~= "" then
		str = " HAVING "..str
	end
	return str
end
	
local function parseOrder(p)
	local str = ""
	if p then
		if type(p) == "string" then 
			str = p
		end
	end
	str = string.gsub(str, "^%s*(.-)%s*$", "%1")
	if str ~= "" then
		str = " ORDER BY "..str
	end
	return str
end
	
local function parseLimit(l,p)
	local str = ""
	if l then
		if type(l) == "string"
		or type(l) == "number" then
			l = tonumber(l)
			if l == 0 then return "" end
			p = tonumber(p) or 1
			str = string.format("%d, %d",(p-1)*l, l)
		end
	end
	str = string.gsub(str, "^%s*(.-)%s*$", "%1")
	if str ~= "" then
		str = " LIMIT "..str
	end
	return str
end
	
local function select(tb,limit,cpage)
	local limit = limit or false
	local cpage = cpage or 1
	local str = ""
	str = str .. parseSelect(tb.flds)
	str = str .. parseFrom(tb.name)
	str = str .. parseWhere(tb.where)
	str = str .. parseGroup(tb.group)
	str = str .. parseHaving(tb.having)
	str = str .. parseOrder(tb.order)
--	str = str .. parseGroup(tb.group)
	str = str .. parseLimit(limit,cpage)
	return str
end

local function setCols(cur)
	local cols = {}
	if cur then
		local tmpCols = cur:getcolnames()
		local tmpType = cur:getcoltypes()
		for i, k in ipairs(tmpCols) do
			cols[i] = {}
			cols[i].name = k
			local _, _, t, l = string.find(tmpType[i],"(%a+)%((%d+)%)")
			cols[i].type = t
			cols[i].len = l
		end
	end
	set = false
	return cols
end

local function setInfo(tb,seltb,connDb)
	local tbi = tb or {}
	if tb == nil then
		tbi.numrows = 0
		tbi.pages = 0
		tbi.limit = 100
		tbi.cols = nil
		return tbi
	end
	local newRows = false
	if tbi.cur then 
		tbi.cur:close()
		tbi.cur = nil
	end
--	or (tbi.limit == 0 and tbi.pages ~= 1)
	if tbi.limit > 0 then
		if tbi.numrows == 0
		or seltb.filterChanged == true
		then
			tbi.cur = connDb:execute(select(seltb))
			if tbi.cur then
				tbi.numrows = tbi.cur:numrows()
				newRows = true
			else
				tbi.numrows = 0
			end
			tbi.filterChanged = false
--[[
print("-------------------------------------------------------")
print("---------  Calcula numero de registros  ---------------")
print("-------------------------------------------------------")			
]]
		end
		tbi.pages = calcPages(tbi.numrows, tbi.limit)
	end
	if seltb.cpage == nil 
	or seltb.cpage == 0 
	then 
		seltb.cpage = 1 
		seltb.newPage = true
	end
--	if tbi.pages > 1 and seltb.filterChanged == true
	if seltb.filterChanged == true
	or seltb.newPage == true
	then
--		if seltb.cpage == nil or seltb.cpage == 0 then seltb.cpage = 1 end
		if tbi.cur then
			tbi.cur:close()
			tbi.cur = nil
		end
--print(select(seltb,tbi.limit,seltb.cpage))
--[[
print("-------------------------------------------------------")
print("-----------   Lee registros a mostrar   ---------------")
print("-------------------------------------------------------")			
]]
		tbi.regs = 0
		local sql = select(seltb,tbi.limit,seltb.cpage)
		tbi.sql = sql
		tbi.cur = connDb:execute(sql)
		if tbi.cur then 
			newRows = true 
			tbi.regs = tbi.cur:numrows()
		end
		seltb.newPage = false
--print("creo nuevo cursor")		
	end
	seltb.filterChanged = false
	if seltb.flsdChanged == true then
		tbi.cols = nil
		if tbi.cur then
--[[
print("-------------------------------------------------------")
print("-----------   Lee columnas  a mostrar   ---------------")
print("-------------------------------------------------------")			
]]
			tbi.cols = setCols(tbi.cur)
			seltb.flsdChanged = false
			newRows = true
		end
		seltb.flsdChanged = false
	end
	tbi.newRows = newRows
end

local function tbsel(tb,connDb)
	local set = {}
	local name = tname
	local flsd = nil
	local where = nil
	local group = nil
	local having = nil
	local order = nil
	local limit = nil
	local cpage = 0
end

function dbtable(tname, connDb)
    local set = {}
	local connDb = connDb
	local dbinfo = setInfo()
	local dbsel = {}
		dbsel.name = tname
		dbsel.flsd = nil
		dbsel.flsdChanged = true
		dbsel.where = nil
		dbsel.group = nil
		dbsel.having = nil
		dbsel.filterChanged = true
		dbsel.order = nil
		dbsel.cpage = 0
--	local rows = {}
--	local limit = nil
--	local cpage = 0
    return setmetatable(set, {__index = {
		getName = function (set)
			return tname
		end,
		setLimit = function (set, value)
			dbinfo.limit = value or 100
			dbsel.newPage = true
			
		end,
		setPage = function (set, value)
			if value then
				dbsel.newPage = true
				if value == "all" then
					dbsel.cpage = 1
					dbinfo.limit = 0
				elseif value == "last" then
					setInfo(dbinfo, dbsel, connDb)
					dbsel.cpage = dbinfo.pages
					dbsel.newPage = true
				else
					if dbsel.cpage == value then dbsel.newPage = false end
					dbsel.cpage = value
				end
			end
		end,
		getChanged = function (set)
			return changed
		end,
		getRows = function (set)
			return dbinfo.rows
		end,
		getFields = function (set)
			return flds
		end,
		getWhere = function (set)
			return where
		end,
		getGroup = function (set)
			return group
		end,
		getHaving = function (set)
			return having
		end,
		getOrder = function (set)
			return order
		end,
		getLimit = function (set)
			return dbinfo.limit
		end,
		getCols = function (set)
			return dbinfo.cols
		end,
		getInfo = function (set)
			setInfo(dbinfo, dbsel, connDb)
			local t = {}
			t.numrows = dbinfo.numrows
			t.pages = dbinfo.pages
			t.page = dbsel.cpage
			t.cols = dbinfo.cols
			t.regs = dbinfo.regs
			return t
--			return dbinfo.numrows, dbinfo.pages, dbsel.cpage, #dbinfo.cols
		end,
		setOrder = function (set, value)
			dbsel.order = value
			dbsel.filterChanged = true
		end,
		setGroup = function (set, value)
			dbsel.group = value
			dbsel.filterChanged = true
		end,
		setNumrows = function (set, value)
			dbinfo.numrows = value
			dbsel.filterChanged = false
		end,
		read = function (set, value)
			set:setPage(value)
			setInfo(dbinfo,dbsel,connDb)
			local ret
			if dbinfo.newRows then
				dbinfo.rows = nil
				local rows = {}
				local row = dbinfo.cur:fetch ({}, "a")
				while row do
--[[
					for k,v in pairs(row) do
						row[k] = string.encode(v)
					end
]]
					rows[#rows+1] = row
					row = dbinfo.cur:fetch ({}, "a")
				end
				dbinfo.cur:close()
				dbinfo.cur = nil
				ret = set:getInfo()
				ret.rows = rows
				ret.sql = dbinfo.sql;
			end
			return ret
		end,
		setFlds = function (set, value)
			dbsel.flds = value
			dbsel.fldsChanged = true
		end,
		setWhere = function (set, value)
			dbsel.where = value
			dbsel.filterChanged = true
		end
    }})
end
