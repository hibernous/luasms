require("iw.addon.string")
__ENV = {}
__FORM = {}

function get_env()
	local t = {}
	local  myenv = io.popen("set")
	for line in myenv:lines() do
		_, _, key, value = string.find(line, "([A-Z_0-9a-z]+)[%=]+(.*)")
--print(line, key, value)
		if key then
			t[key] = value
		end
	end
--print("-------------------------------------------------------")
	return t
end

function processInfo(str,data)
	local lines = string.split(str,"\r\n")
	local retKey = ""
	local retData = {}
	local count = 0
	for i=1, #lines do
		local fields = string.split(lines[i],"; ")
		_, _, content, ctype = string.find(fields[1],"(.+): (.+)")
		if string.lower(content) == "content-disposition" then
			for n=2, #fields do
				local _, _, key, value = string.find(fields[n],"(.+)=(.+)")
				if value then value = string.gsub(value,'"',"") end
				if key == "name" then
					retKey = value
				else
					retData[key]=value
					count = count+1
				end
			end
			retData["data"]=data
			count = count+1
		end
	end
	if count == 1 then
		return retKey, data
	end
	return retKey, retData
end

function get_data(str)
	local i, e = string.find(str,"\r\n\r\n")
	local data = string.sub(str,e+1)
	local key
	key, data = processInfo(string.sub(str,1,i-1), data)
	return key, data
end

function proscessQueryString(data)
	local post = {}
	local char = "="
		for l in string.gmatch(data,"[^&]+") do
			l = string.gsub(l,"["..char.."]%s+",char)
			local _, _, key, value = string.find(l, "(.+)%s*["..char.."]%s*(.*)")
			key = string.trim(key)
			value = string.trim(value)
			if key ~= nil then
				post[key]=value
			end
		end
	return post
end

function process_post(data)
	local t = {}
	local ini, pos = string.find(data,"\r\n")
	if ini == nil 
	and pos == nil 
	and data:match("=") then
		return proscessQueryString(data)
	end
	local sepend = string.sub(data,1,ini-1)
	ini = 1
	local pos, ini = string.find(data, sepend, ini)
	ini = ini+2
	while true do
		local pos, pend = string.find(data, sepend, ini)
		if pos == nil then break end
		local str=string.sub(data,ini,pos-3)
		local key, value = get_data(str)
		t[key] = value
		ini = pend+3
	end
	return t
end

function get_post()
	local post = {}
	local char = string.char(255)
	local lowchar = string.char(0)
	local data = os.getenv("QUERY_STRING")
	local method = os.getenv("REQUEST_METHOD")
	if method == nil then 
		if #arg >= 0 then
			for i=1, #arg do
				local _, _, k, v = string.find(arg[i],"(.+)=(.+)")
				post[k]=v
			end
		end
		return post
	end
	if method == "GET" then char = "=" end
	local key, value
	if method == "POST" then
		data = io.stdin:read"*a"
		return process_post(data)
	end
	if data then
		post = proscessQueryString(data)
	end
	return post
end
__ENV = get_env()
__FORM = get_post()
