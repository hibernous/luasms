--------------------------------------------------------------------------------
-- htmlpageClass.lua
--
-- Author(s) [in order of work date]:
--       Fabián Omar Franzotti
--
--------------------------------------------------------------------------------
--
--	usage : page = pageClass.new(title_of_page)
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
require("html.htmlClass")
--require("addon.uci")
--require ("xwrt.hmenu")
--__MENU = htmlhmenuClass.new()
--__MENU:loadXWRT()

pageClass = htmlpageClass

function pageClass:init()
	self.head.title = self.title  
		self.path = {}
	self["image"] = nil
--	if __ENV then
--		self["form"] = [[<form enctype="multipart/form-data" action="]]..(__ENV.SCRIPT_NAME or "")..[[" method="post">]]
--	end
--	self.head.links:add({rel="stylesheet", type="text/css", href="/themes/active/waitbox.css", media="screen"})
	self.head.links:add({rel = "stylesheet", type = "text/css", href = "themes/active/webif.css"})
--	self.head.scripts:add({	type="text/javascript", src="/js/styleswitcher.js"})
	self.head.metas:add({
				{ ["http-equiv"] = "Content-Type", content = [[text/html; charset=UTF-8]]},
				{ ["http-equiv"] = "expires", content = "-1" }
			})

	self.container:add(htmlsectionClass.new("div","header"))
	self.container.header:add(self:set_header())

--	self.container:add(self:set_menu())

--	if self.form then
--		self.container:add(self.form)
--	end

	self.container:add(htmlsectionClass.new("div","content"))
	self.container.content:add(self:set_content())

	self.container:add(self:set_footer())

	self.content = self.container.content
end

--------------------------------------------------------------------------------
-- functions to set defaults values of header, content and footer or x-wrt page
--------------------------------------------------------------------------------
function pageClass:set_header()
	return function()
			return ""--"<img src='/images/logo.gif' />"
		end
end

function pageClass:set_menu()
	return	function()
						return __MENU:text()
					end
end

function pageClass:set_content()
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

function pageClass:set_footer()
	return function ()
		return "footer"
	end
end

function pageClass:start()
	local str = ""
	if self.content_type then str = self.content_type end
	if self.doc_type then str = str .. self.doc_type end
	str = str .. (self.html or "<HTML>\n")
	str = str .. self.head:text()
print("self.head")
	str = str .. (self.body or "<BODY>") .. "\n"
	str = str .. '<div ID="container">' .. '\n'
	str = str .. '<div ID="header">' .. '\n'
	str = str .. self.set_header()()
	str = str .. '</div> <!-- header -->' .. '\n'
--	str = str .. '<div ID="mainmenu"></div>' .. "\n"
--	str = str .. self:set_menu()()
--	str = str .. self.form .. '\n'
	str = str .. '<div ID="content">' .. '\n'
	str = str .. '<h2>'.. self.title .. '</h2>' 
	return str
end

function pageClass:the_end()
	local str = '</div> <!-- content -->' .. '\n'
	str = str .. self:set_footer()()
	str = str .. '</div> <!-- container -->' .. '\n'
	str = str .. '</BODY>' .. "\n"
	str = str .. '</HTML>' .. "\n"
	return str
end
