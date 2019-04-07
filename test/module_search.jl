import Box0: Usb

dev = Usb.open_supported()
mod = Box0.search(dev, Box0.AIN, Int32(0))
println(mod)
println(Box0.name(mod))
Box0.close(dev)
