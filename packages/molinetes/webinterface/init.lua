package.path = "/var/www/molinetes/?.lua;/var/www/molinetes/lua/?.lua;"..package.path
require("utils.cgi_env")
require("connect")
require("addon.string")
require("utils.translator")
require("molinetes.page")
page = pageClass.new("Testing")
page.content:add("algo")
