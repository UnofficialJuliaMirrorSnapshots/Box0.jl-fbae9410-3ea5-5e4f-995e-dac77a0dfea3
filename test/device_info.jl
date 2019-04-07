import Box0
import Box0.Usb

dev = Usb.open_supported()
println("name: ", Box0.name(dev))
println("manuf: ", Box0.manuf(dev))
println("serial: ", Box0.serial(dev))
Box0.close(dev)
