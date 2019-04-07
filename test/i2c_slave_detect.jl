import Box0: Usb, ResultException, WARN
import Box0: i2c, master_prepare, close, master_slave_detect, log

dev = Usb.open_supported()
log(dev, WARN)
i2c0 = i2c(dev)
master_prepare(i2c0)

found = false

for i::UInt8 in 0b0001000:0b1110111
	try
		if master_slave_detect(i2c0, i)
			println("Slave detected on: 0x", hex(i))
			found = true
		end
	catch e
		if !isa(e, ResultException)
			throw(e)
		end
	end
end

if !found
	println("No I2C Slave found!")
end

close(i2c0)
close(dev)
