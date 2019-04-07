import Box0
import Box0: Usb
import Box0: log, ain, snapshot_prepare, close, chan_seq_set, chan_seq_get

dev = Usb.open_supported()
log(dev, Box0.DEBUG)
ain0 = ain(dev)
snapshot_prepare(ain0)

data = Array{Cuint}([0, 1, 3])

println("setting ", data)
chan_seq_set(ain0, data)

data = chan_seq_get(ain0)
println("got back ", data)

close(ain0)
close(dev)
