import Box0: Usb

dev = Usb.open_supported()
for mod in dev
	println(mod, " Openable ", Box0.openable(mod))
end
Box0.close(dev)
