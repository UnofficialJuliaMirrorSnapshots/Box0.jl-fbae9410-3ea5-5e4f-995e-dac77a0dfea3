import Box0
import Box0: Usb
import Box0: log, ain, snapshot_prepare, snapshot_start, close, bitsize_speed_set

BITSIZE = Cuint(12)
SPEED = Culong(60000) # 600KS/s

dev = Usb.open_supported()
log(dev, Box0.DEBUG)
ain0 = ain(dev)
snapshot_prepare(ain0)

bitsize_speed_set(ain0, BITSIZE, SPEED)
val = Array{Float32}(100)
snapshot_start(ain0, val)

println(val)
close(ain0)
close(dev)

using PyPlot: plot, show, title
x = linspace(0, length(val) / float(SPEED), length(val))
y = val
plot(x, y, color="red")
title("AIN0 test data")
show()
