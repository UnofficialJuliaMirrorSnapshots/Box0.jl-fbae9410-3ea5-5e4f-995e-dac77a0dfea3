import Box0: Usb
import Box0: pwm, output_prepare, output_start, output_stop, output_calc,
		field_bitsize, period_set, speed_set, width_set, output_calc_width

pin0 = Cuint(0)

dev = Usb.open_supported()
pwm0 = pwm(dev)
output_prepare(pwm0)

bitsize = unsafe_load(field_bitsize(pwm0).values, 1) # first bitsize
speed, period = output_calc(pwm0, bitsize, 1.0)
println("speed, period: ", speed, ", ", period)

speed_set(pwm0, speed)
period_set(pwm0, period)
width_set(pwm0, pin0, output_calc_width(period, 50.0))

output_start(pwm0)

while true
	sleep(1)
end

output_stop(pwm0)

close(pwm0)
close(dev)
