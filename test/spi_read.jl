import Box0: Usb
import Box0: master_prepare, master_start, spi, close
import Box0: SpiTaskFd

dev = Usb.open_supported()
spi0 = spi(dev)
master_prepare(spi0)

out = Array{UInt8}([0x48, 0x26, 0x98, 0x89, 0x38])
in = Array{UInt8}(5)

task = [SpiTaskFd(0, out, in, bitsize=8), SpiTaskFd(0, out, in, bitsize=8, last=true)]
master_start(spi0, task)

println("out[:] ", out[:])
println("in[:] ", in[:])
if out[:] == in[:]
	println("Data matched!")
else
	println("We have problem, data did not match")
end

close(spi0)
close(dev)
