rs232 = require ("luars232")
function openPort(rsport)
	e, dev = rs232.open(rsport)
	local info
	if e ~= rs232.RS232_ERR_NOERROR then
		-- handle error
		info = string.format("can't open serial port '%s', error: '%s'\n",
		rsport, rs232.error_tostring(e))
	else
		assert(dev:set_baud_rate(rs232.RS232_BAUD_115200) == rs232.RS232_ERR_NOERROR)
		assert(dev:set_data_bits(rs232.RS232_DATA_8) == rs232.RS232_ERR_NOERROR)
		assert(dev:set_parity(rs232.RS232_PARITY_NONE) == rs232.RS232_ERR_NOERROR)
		assert(dev:set_stop_bits(rs232.RS232_STOP_1) == rs232.RS232_ERR_NOERROR)
		assert(dev:set_flow_control(rs232.RS232_FLOW_OFF)  == rs232.RS232_ERR_NOERROR)
		info = string.format("OK, port open with values '%s'", tostring(dev))
	end
	return dev, info
end

