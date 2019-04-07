import Box0
import Box0: Usb
import Box0: log, ain, snapshot_prepare, close, bitsize_speed_set, bitsize_speed_get

dev = Usb.open_supported()
log(dev, Box0.DEBUG)
ain0 = ain(dev)
snapshot_prepare(ain0)

println("setting ", 12, ", ", 1000)
bitsize_speed_set(ain0, Cuint(12), Culong(1000))

bitsize, speed = bitsize_speed_get(ain0)
println("got back", bitsize, ", ", speed)

close(ain0)
close(dev)
