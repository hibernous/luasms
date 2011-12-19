--------------------------------------------------------------------------------
-- htmlpageClass.lua
--
-- Author(s) [in order of work date]:
--       Fabi�n Omar Franzotti
--
--------------------------------------------------------------------------------
--
--	usage : page = voiceipPageClass.new(title_of_page)
--	page instances
--		page.content_type		(get or set) default value come from htmlpageClass
--		page.doc_type				(get or set) default value come from htmlpageClass
--		page.html						(get or set) default value come from htmlpageClass
--		page.head						(get or set)
--		page.head.title			(get or set)
--		page.head.links			(get or set)
--		page.head.metas			(get or set)
--		page.head.scripts		(get or set)
--		page.body						(get or set)
--		page.container			(get or set)
--		page.container.header
--		page.container.content
--		page.content = page.container.content (this is a shortcat to real instance )
--		page.savebutton
--		page.action_apply
--		page.action_clear
--		page.action_review
--		page.image
--	page functions
--		page.head.links:add({rel="stylesheet",type="text/css",href="/path/to/file.css", media="screen", ......})
--			or you can set it page.head.links = [[<link rel="stylesheet" type="text/css" href="/themes/active/waitbox.css" media="screen" />
--	<link rel="stylesheet" type="text/css" href="/themes/active/webif.css" />
--	]]
--				but this way destroy the page.head.links:add(...) funtions.
--		also you can set page.head = [[
--<head>
--<title>System - OpenWrt Kamikaze Administrative Console</title>
--	<link rel="stylesheet" type="text/css" href="/themes/active/waitbox.css" media="screen" />
--	<link rel="stylesheet" type="text/css" href="/themes/active/webif.css" />
--	
--	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
--	<meta http-equiv="expires" content="-1" />
--	<script type="text/javascript" src="/js/styleswitcher.js"></script>
--</head>
--]]
--			but this way destroy all page.head instances and funtions to add values in dinamic way
--
--		page.head.metas:add({["http-equiv"] = "Content-Type", content = [[text/html; charset=UTF-8]], ......})
--		page.head.metas:add({["http-equiv"] = "Content-Type", content = [[text/html; charset=UTF-8]], ......})
--		page.container:add("add html code to container")
--
--------------------------------------------------------------------------------
require("iw.html.htmlClass")
--require("iw.addon.uci")
require ("iw.voiceip.hmenu")
__MENU = htmlhmenuClass.new()
--__MENU:loadXWRT()

voiceipPageClass = htmlpageClass

function voiceipPageClass:init()
	self.head.title = self.title --.. " - "..uci.get("webif","general","firmware_name").." "..tr("Administrative Console") 
	self["savebutton"]    = "<input type=\"submit\" name=\"__ACTION\" value=\""..tr("Save Changes").."\" />"
	self["action_apply"] = nil
	self["action_clear"]  = nil
	self["action_review"] = nil
	self["image"] = nil
	if __ENV then
		self["form"] = [[<form enctype="multipart/form-data" action="]]..(__ENV.SCRIPT_NAME or "")..[[" method="post">]]
	end
	self.head.links:add({rel="stylesheet", type="text/css", href="/themes/active/waitbox.css", media="screen"})
	self.head.links:add({rel = "stylesheet", type = "text/css", href = "/themes/active/webif.css"})
	self.head.scripts:add({	type="text/javascript", src="/js/styleswitcher.js"})
	self.head.metas:add({
				{ ["http-equiv"] = "Content-Type", content = [[text/html; charset=UTF-8]]},
				{ ["http-equiv"] = "expires", content = "-1" }
			})

	self.container:add(htmlsectionClass.new("div","header"))
	self.container.header:add(self:set_header())

	self.container:add(self:set_menu())

	if self.form then
		self.container:add(self.form)
	end

	self.container:add(htmlsectionClass.new("div","content"))
	self.container.content:add(self:set_content())

	self.container:add(self:set_footer())

	self.content = self.container.content
end

--------------------------------------------------------------------------------
-- functions to set defaults values of header, content and footer or x-wrt page
--------------------------------------------------------------------------------
function voiceipPageClass:set_header()
	return function()
--		sys = util.uptime()
		dt = os.date("*t")
					return [[	<img src="/images/logo.gif" />
	<em>]]..tr("making_usable#End user extensions for OpenWrt")..[[</em>
	<h1>]]..tr("X-Wrt Administration Console")..[[</h1>
	<div id="short-status">
		<h3><strong>]]..tr("Status")..[[ :</strong></h3>
	<fieldset id="message">
	<legend><strong>]]..tr("Openwrt Backfire x.xx.xx")..[[</strong></legend>
		<ul>
			<li><strong>]]..tr("Host")..[[:</strong> ]]..(__ENV.hostname or "")..[[</li>
			<li><strong>]]..tr("Date")..[[:</strong> ]]..string.format("%4d-%02d-%02d",dt.year,dt.month,dt.day)..[[</li>
			<li><strong>]]..tr("Uptime")..[[:</strong> ]].."Hora prendido"..[[</li>
			<li><strong>]]..tr("Time")..[[:</strong> ]]..string.format("%02d:%02d:%02d",dt.hour,dt.min,dt.sec)..[[</li>
			<li><strong>]]..tr("Load")..[[:</strong> ]].."Procesor Info"..[[</li>
		</ul>
	</fieldset>
	</div>
]]
				end
end

function voiceipPageClass:set_menu()
	return	function()
						return __MENU:text()
					end
end

function voiceipPageClass:set_content()
	return function()
					local str = "<h2>"
					if self.container.content.image then
						str = str .."<img src=\""..self.container.content.image.."\" alt=\""..tr(self.title).."\" />&nbsp;"..tr(self.title)
					else
						str = str .. tr(self.title)
					end
					str = str .."</h2>\n"
--					self.container.content:add(str)
--					if __WIP ~= nil and __WIP >0 then self.container.content:add("<h3 CLASS=\"warning\"> "..tr(__WORK_STATE[__WIP]).."</h3>") end
					return str 
				end
end

function voiceipPageClass:set_footer()
	return function ()
	local uci_count = 0;--uci.updated()
	local str = "<div class=\"page-save\">"
	local footer = [[
<br />
<fieldset id="save">
	<legend><strong>]]..tr("Proceed Changes")..[[</strong></legend>
]]
	if self.form ~= nil and self.form ~= "" then footer = footer..self.savebutton end

	footer = footer .. [[
	<ul class="apply">
]]
	if uci_count > 0 then
		footer = footer ..[[
		<li>]]..self.action_apply..[[</li>
		<li>]]..self.action_clear..[[</li>
		<li>]]..self.action_review..[[</li>
]]
	end
	footer = footer .. [[
	</ul>
]]

	footer = footer ..[[

</fieldset>
]]
	if self.form ~= nil and self.form ~= "" then footer = footer.."</form>" end
	footer = footer ..[[

<hr />
<div id="footer">
	<h3>X-Wrt</h3>
	<em>]]..tr("making_usable#End user extensions for OpenWrt")..[[</em>
</div>]]
	return footer
	end
end

function str_footer()
end

function voiceipPageClass:start()
	local str = ""
	if self.content_type then str = self.content_type end
	if self.doc_type then str = str .. self.doc_type end
	str = str .. (self.html or "<HTML>\n")
	str = str .. self.head:text()
	str = str .. (self.body or "<BODY>") .. "\n"
	str = str .. '<div ID="container">' .. '\n'
	str = str .. '<div ID="header">' .. '\n'
	str = str .. self.set_header()()
	str = str .. '</div> <!-- header -->' .. '\n'
--	str = str .. '<div ID="mainmenu"></div>' .. "\n"
	str = str .. self:set_menu()()
	str = str .. self.form .. '\n'
	str = str .. '<div ID="content">' .. '\n'
	str = str .. '<h2>'.. self.title .. '</h2>' 
	return str
end

function voiceipPageClass:the_end()
	local str = '</div> <!-- content -->' .. '\n'
	str = str .. self:set_footer()()
	str = str .. '</div> <!-- container -->' .. '\n'
	str = str .. '</BODY>' .. "\n"
	str = str .. '</HTML>' .. "\n"
	return str
end
