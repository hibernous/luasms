require "lanes"
require("testing")
	local pepon = repepito
	local function pepito()
		print("pepito")
		pepon()
	end
	
	local function pepe()
		print("Algo")
		pepito()
	end
	
	f= lanes.gen( function(n) return 2*n end )
	g= lanes.gen( "*", {globals = _G},  pepe )
	a= f(1)
	b= f(2)
	c= g()
	print( a[1], b[1], c[1] )     -- 2    4
 
