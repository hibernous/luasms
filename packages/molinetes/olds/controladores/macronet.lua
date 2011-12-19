require("ctrls_common")
trjs = {
"EDB0C93A", 
"2680A721",
"FA772803",
"21FD7711",
"10810103",
"00EDB0C9",
"3A0980FE",
"5321AE77",
"13CD5871",
"C36A13AF",
"322780CD",
"636F3A29",
"80FE0120",
"14CD5670",
"CDF16D06",
"03CD1D23"
}
for i=1, #trjs do
	print(trjs[i], string.hex2dec(trjs[i]))
end
