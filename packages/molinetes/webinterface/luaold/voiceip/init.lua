old_require = require

function exists(file)
    local f = io.open( file, "r" )
    if f then
        io.close( f )
        return true
    else
        return false
    end
end

function require (str)
	local fstr = string.gsub(str,"[.]","/")
	for path in string.gmatch(package.path,"[^;]+") do
		local path = string.gsub(path,"?",fstr)
		if exists(path) then
			return old_require(str)
		end
	end
	for path in string.gmatch(package.cpath,"[^;]+") do
		local path = string.gsub(path,"?",fstr)
		if exists(path) then
			return old_require(str)
		end
	end
	return nil
end

	__ENV = {}
	__FORM = {}
	__WORK_STATE = {"Warning... WORK NOT DONE... Not usefull...","Warning... Work in progress...","Warning... Work Not Tested","Warning... Work in Test"}
	__WIP = 0 
	__ERROR   = {} -- __ERROR[#__ERROR][var_name], __ERROR[#__ERROR][msg]
	__TOCHECK = {} -- __TOCHECK[#__TOCHECK]
	__UCI_CMD = {} -- __UCI_CMD[#__UCI_CMD]["command"], __UCI_CMD[#__UCI_CMD_]["varname"]
	__UCI_MSG = {} -- 
	__ERROR = {}
	__ENV = {}
	__FORM = {}
	__MENU = {}
	require("iw.utils.cgi_env")
--	require("iw.xwrt.validate")
--	require("iw.addon.uci")
--	require("iw.xwrt.changes_uci")
--	uci_changed = changes_uciClass.new()
	require("iw.voiceip.translator")
	tr_load()
	util = require("iw.voiceip.util")
	require("iw.voiceip.page")
	page = voiceipPageClass.new("VoiceIP Page")
	require("iw.html.form")
--	__MENU.permission()
--	if __FORM.__ACTION=="clear_changes"  then uci_changed:clear() end
--	if __FORM.__ACTION=="apply_changes"  then uci_changed:apply() end
--	if __FORM.__ACTION=="review_changes" then uci_changed:show() end
