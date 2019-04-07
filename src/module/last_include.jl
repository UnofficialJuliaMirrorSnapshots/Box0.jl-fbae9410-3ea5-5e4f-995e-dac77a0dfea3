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

export open, close
export ain, aout, spi, i2c, pwm, dio, device, index, name
export bitsize_get, speed_get, repeat_get, bitsize_speed_get
export chan_seq_get, snapshot_start


for (t::Type, n::String) in ((Ain, "ain"), (Aout, "aout"), (Spi, "spi"),
									(I2c, "i2c"), (Pwm, "pwm"), (Dio, "dio"))
	func_close = "b0_"*n*"_close"
	func_open = "b0_"*n*"_open"
	open_by_name = Symbol(n)

	@eval begin
		close(mod::Ptr{$t}) = act(ccall(($func_close, "libbox0"),
			ResultCode, (Ptr{$t}, ), mod))

		open(dev::Ptr{Device}, mod::Ref{Ptr{$t}}, index::Cint = Cint(0)) =
			act(ccall(($func_open, "libbox0"), ResultCode,
					(Ptr{Device}, Ref{Ptr{$t}}, Cint), dev, mod, index))

		$open_by_name(dev::Ptr{Device}, index::Cint = Cint(0)) =
			(mod = Ref{Ptr{$t}}(0); open(dev, mod, index); mod[])

		# direct access to header
		device(mod::Ptr{$t}) = deref(mod).header.device
		index(mod::Ptr{$t}) = deref(mod).header.index
		name(mod::Ptr{$t}) = unsafe_string(deref(mod).header.name)
	end

	# access to properties using method
	for field in fieldnames(t)
		if field != :header
			access_field = Symbol("field_"*string(field))
			@eval begin
				$access_field(mod::Ptr{$t}) = deref(mod).$field
				export $access_field
			end
		end
	end
end

function open(mod::Ptr{Module_})
	for (t::ModuleType, func::Function) in ((AIN, ain), (AOUT, aout),
							(SPI, spi), (I2C, i2c), (PWM, pwm), (DIO, dio))
		if mod.type == t
			return func(device(mod), index(mod))
		end
	end
	error("Module(", mod, ") type unknown")
end

# Some common code

snapshot_start{M,T}(mod::Ptr{M}, samples::Ptr{T}, count::Integer) =
	snapshot_start(mod, samples, Csize_t(count))

snapshot_start{M,T}(mod::Ptr{M}, samples::Array{T}) =
	snapshot_start(mod, pointer(samples), length(samples))

function chan_seq_get{M}(mod::Ptr{M}, values::Array{Cuint})
	count = Ref{Csize_t}(length(values))
	chan_seq_get(mod, pointer(values), count)
	return values[1:count[]]
end

function chan_seq_get{M}(mod::Ptr{M})
	target = field_chan_count(mod) + 1
	while true
		values = chan_seq_get(mod, Array{Cuint}(target))
		if length(values) < target
			return values
		end
		target *= 2
	end
end

function bitsize_speed_get{M}(mod::Ptr{M})
	bitsize = Ref{Cuint}(0)
	speed = Ref{Culong}(0)
	_bitsize = Ptr{Cuint}(pointer_from_objref(bitsize))
	_speed = Ptr{Culong}(pointer_from_objref(speed))
	bitsize_speed_get(mod, _bitsize, _speed)
	return bitsize[], speed[]
end

function repeat_get{M}(mod::Ptr{M})
	value = Ref{Culong}(0)
	repeat_get(mod, value)
	value[]
end

function speed_get{M}(mod::Ptr{M})
	val = Ref{Culong}(0)
	speed_get(mod, val)
	val[]
end

function bitsize_get{M}(mod::Ptr{M})
	val = Ref{Cuint}(0)
	bitsize_get(mod, val)
	return val[]
end
