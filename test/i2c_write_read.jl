import Box0: Usb
import Box0: master_prepare, master_start, i2c, close
import Box0: I2cTask, I2cTaskWrite, I2cTaskRead

dev = Usb.open_supported()
i2c0 = i2c(dev)
master_prepare(i2c0)

out = Array{UInt8}([0x48, 0x26, 0x98])
in = Array{UInt8}(1)

tasks = Array{I2cTask}([I2cTaskWrite(0x77, out), I2cTaskRead(0x77, in, last=true)])
println(tasks)
println(sizeof(tasks))
start(i2c0, tasks)

println("out[:] ", out[:])
println("in[:] ", in[:])

close(i2c0)
close(dev)
