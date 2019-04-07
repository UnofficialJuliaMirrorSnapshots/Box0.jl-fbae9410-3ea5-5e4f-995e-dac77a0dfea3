import Box0: Usb
import Box0: DISABLE, dio, basic_prepare, basic_start, basic_stop, hiz, output, low, toggle, close

pin0 = UInt8(0)

dev = Usb.open_supported()
dio0 = dio(dev)
basic_prepare(dio0)

hiz(dio0, pin0, DISABLE)
output(dio0, pin0)
low(dio0, pin0)

basic_start(dio0)

while true
	toggle(dio0, pin0)
	sleep(1)
end

basic_stop(dio0)

close(dio0)
close(dev)
