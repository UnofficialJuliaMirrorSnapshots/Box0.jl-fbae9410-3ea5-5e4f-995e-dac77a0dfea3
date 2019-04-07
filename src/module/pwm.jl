#
# This file is part of Box0.jl.
# Copyright (C) 2015, 2016 Kuldeep Singh Dhaka <kuldeep@madresistor.com>
#
# Box0.jl is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Box0.jl is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Box0.jl.  If not, see <http://www.gnu.org/licenses/>.
#

export Pwm, PwmReg
export output_prepare, output_start, output_stop, output_calc
export width_get, width_set, period_set, period_get, speed_set, speed_get
export bitsize_set, bitsize_get
export output_calc_freq_error, output_calc_freq
export output_calc_duty_cycle, output_calc_width

immutable PwmRef
	high::Float64
	low::Float64
	type_::RefType
end

immutable PwmLabel
	pin::Ptr{Ptr{UInt8}}
end

immutable PwmBitsize
	values::Ptr{Cuint}
	count::Csize_t
end

immutable PwmSpeed
	values::Ptr{Culong}
	count::Csize_t
end

type Pwm
	header::Module_
	pin_count::Cuint
	label::PwmLabel
	bitsize::PwmBitsize
	speed::PwmSpeed
	ref::PwmRef
end

const PwmReg = Culonglong

width_set(mod::Ptr{Pwm}, ch::Cuint, width::PwmReg) =
	act(ccall(("b0_pwm_width_set", "libbox0"), ResultCode,
		(Ptr{Pwm}, Cuint, PwmReg), mod, ch, width))

width_get(mod::Ptr{Pwm}, ch::Cuint, width::Ptr{PwmReg}) =
	act(ccall(("b0_pwm_width_get", "libbox0"), ResultCode,
		(Ptr{Pwm}, Cuint, Ptr{PwmReg}), mod, ch, width))

function width_get(mod::Ptr{Pwm}, ch::Cuint)
	val::PwmReg = 0
	width(mod, Ptr{PwmReg}(pointer_to_objref(val)), ch)
	return val
end

period_set(mod::Ptr{Pwm}, period::PwmReg) =
	act(ccall(("b0_pwm_period_set", "libbox0"), ResultCode,
		(Ptr{Pwm}, PwmReg), mod, period))

period_get(mod::Ptr{Pwm}, period::Ptr{PwmReg}) =
	act(ccall(("b0_pwm_period_get", "libbox0"), ResultCode,
		(Ptr{Pwm}, Ptr{PwmReg}), mod, period))

function period_get(mod::Ptr{Pwm})
	val::PwmReg = 0
	period(mod, Ptr{PwmReg}(pointer_to_objref(val)))
	return val
end

speed_set(mod::Ptr{Pwm}, speed::Culong) =
	act(ccall(("b0_pwm_speed_set", "libbox0"), ResultCode,
			(Ptr{Pwm}, Culong), mod, speed))

speed_get(mod::Ptr{Pwm}, speed::Ptr{Culong}) =
	act(ccall(("b0_pwm_speed_get", "libbox0"), ResultCode,
			(Ptr{Pwm}, Ptr{Culong}), mod, speed))

bitsize_set(mod::Ptr{Pwm}, bitsize::Cuint) =
	act(ccall(("b0_pwm_bitsize_set", "libbox0"), ResultCode,
			(Ptr{Pwm}, Cuint), mod, bitsize))

bitsize_get(mod::Ptr{Pwm}, bitsize::Ref{Cuint}) =
	act(ccall(("b0_pwm_bitsize_get", "libbox0"), ResultCode,
			(Ptr{Pwm}, Ptr{Cuint}), mod, bitsize))

output_calc(mod::Ptr{Pwm}, bitsize::Cuint, freq::Float64,
		speed::Ref{Culong}, period::Ref{PwmReg}, max_error::Float64,
		best_result::Cbool = Cbool(true)) =
	act(ccall(("b0_pwm_output_calc", "libbox0"), ResultCode,
		(Ptr{Pwm}, Cuint, Float64, Ref{Culong}, Ref{PwmReg}, Float64, Cbool),
		mod, bitsize, freq, speed, period, max_error, best_result))

function output_calc(mod::Ptr{Pwm}, bitsize::Cuint, freq::Float64,
			max_error::Float64 = Float64(100), best_result::Bool = true)
	speed = Ref{Culong}(0)
	period = Ref{PwmReg}(0)
	output_calc(mod, bitsize, freq, speed, period, max_error, Cbool(best_result))
	return speed[], period[]
end

output_prepare(mod::Ptr{Pwm}) =
	act(ccall(("b0_pwm_output_prepare", "libbox0"), ResultCode, (Ptr{Pwm}, ), mod))

output_stop(mod::Ptr{Pwm}) =
	act(ccall(("b0_pwm_output_stop", "libbox0"), ResultCode, (Ptr{Pwm}, ), mod))

output_start(mod::Ptr{Pwm}) =
	act(ccall(("b0_pwm_output_start", "libbox0"), ResultCode, (Ptr{Pwm}, ), mod))

output_calc_width(period::PwmReg, duty_cycle::Float64) =
	PwmReg(period * duty_cycle / 100.0)

output_calc_duty_cycle(period::PwmReg, width::PwmReg) =
	((width * 100.00) / period)

output_calc_freq(speed::Culong, period::PwmReg) = (speed / period)

output_calc_freq_error(required_freq::Float64, calc_freq::Float64) =
	((abs(required_freq - calc_freq) * 100.0) / required_freq)
