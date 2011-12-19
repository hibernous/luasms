socket = require("socket")
local function newAction (action)
	local str = string.format("Action: %s\r\n",action)
    local set = {}
    return setmetatable(set, {__index = {
		add = function (set, var, val)
			str = string.format("%s%s: %s\r\n", str, var, val)
		end,
		text = function (set)
			local id = socket.gettime()
			str = string.format("%sActionID: %s\r\n\r\n",str,id)
			return str
		end
    }})
end

function action()
    local set = {}
    return setmetatable(set, {__index = {
		login = function (set,user,pass,event)
			local event = event or true
			local act = newAction("login")
			act.add("Username",user)
			act.add("Secret", pass)
			if event == false then
				act.add("Events","off")
			end
			return t
		end,
		logoff = function (set, value)
			dbinfo.limit = value or 1000
			dbsel.newPage = true
		end
    }})
end

function ami ()
    local set = {}
	local ResponseWating = {}
	local Events = {}
	local client
	local action
	local response
    return setmetatable(set, {__index = {
		open = function (set,host,port)
			print("Conectando a "..host..":"..port)
			client, serror = socket.connect(host,port)
			if serror then
				print("Connection Error: "..serror)
				os.exit(0)
			else
				local line, serror, buffer = client:receive('*l',buffer)
				print(line,serror, buffer)
			end
		end,
		close = function (set, value)
			dbinfo.limit = value or 1000
			dbsel.newPage = true
		end
    }})
end