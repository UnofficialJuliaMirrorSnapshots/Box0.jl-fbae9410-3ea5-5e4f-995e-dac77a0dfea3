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

export LOW, HIGH, DISABLE, ENABLE, INPUT, OUTPUT
export Dio, Pin, PinGroup
export input, output, high, low, toggle, enable, disable
export value_set, value_get, value_toggle, dir_get, dir_set, hiz_set, hiz_get
export basic_prepare, basic_start, basic_stop
export pin, pin_group
export DIO_CAPAB_OUTPUT, DIO_CAPAB_INPUT, DIO_CAPAB_HIZ

const DioCapab = Cint
DIO_CAPAB_OUTPUT = DioCapab(1 << 0)
DIO_CAPAB_INPUT = DioCapab(1 << 1)
DIO_CAPAB_HIZ = DioCapab(1 << 2)

immutable DioLabel
	pin::Ptr{Ptr{UInt8}}
end

immutable DioRef
	high::Float64
	low::Float64
	type_::RefType
end

immutable Dio
	header::Module_
	pin_count::Cuint
	capab::DioCapab
	label::DioLabel
	ref::DioRef
end

#pin
type Pin
	module_::Ptr{Dio}
	index::Cuint
end

pin(mod::Ptr{Dio}, val::Cuint) = Pin(mod, val)
pin(mod::Ptr{Dio}, val::Integer) = pin(mod, Cuint(val))

#pin group
type PinGroup
	module_::Ptr{Dio}
	indexes::Array{Cuint}
end

pin_group(mod::Ptr{Dio}, indexes::Array{Cuint}) = PinGroup(mod, indexes)
#TODO: convert to array from tuple
pin_group(mod::Ptr{Dio}, indexes::Cuint...) = PinGroup(mod, indexes...)

const LOW = false
const HIGH = true

const DISABLE = false
const ENABLE = true

const INPUT = false
const OUTPUT = true

basic_prepare(mod::Ptr{Dio}) =
	act(ccall(("b0_dio_basic_prepare", "libbox0"), ResultCode, (Ptr{Dio}, ), mod))

basic_start(mod::Ptr{Dio}) =
	act(ccall(("b0_dio_basic_start", "libbox0"), ResultCode, (Ptr{Dio}, ), mod))

basic_stop(mod::Ptr{Dio}) =
	act(ccall(("b0_dio_basic_stop", "libbox0"), ResultCode, (Ptr{Dio}, ), mod))

for n::String in ("dir", "value", "hiz")
	func_get = Symbol(n*"_get")
	func_set = Symbol(n*"_set")

	cfunc_get = "b0_dio_"*n*"_get"
	cfunc_set = "b0_dio_"*n*"_set"

	@eval begin
		$func_set(mod::Ptr{Dio}, pin::Cuint, val::Cbool) =
			act(ccall(($cfunc_set, "libbox0"), ResultCode,
				(Ptr{Dio}, Cuint, Cbool), mod, pin, val))

		#NOTE: remove in future if julia convert Bool and Cbool transparently
		$func_set(mod::Ptr{Dio}, pin::Cuint, val::Bool) = $func_set(mod, pin, Cbool(val))

		$func_set(pin::Pin, val::Cbool) = $func_set(pin.module_, pin.index, val)

		#NOTE: remove in future if julia convert Bool and Cbool transparently
		$func_set(pin::Pin, val::Bool) = $func_set(pin, Cbool(val))

		# ---

		$func_get(mod::Ptr{Dio}, pin::Cuint, val::Ref{Cbool}) =
			act(ccall(($cfunc_get, "libbox0"), ResultCode,
				(Ptr{Dio}, Cuint, Ref{Cbool}), mod, pin, val))

		$func_get(mod::Ptr{Dio}, pin::Cuint) =
			(val = Ref{Cbool}(0); $func_get(mod, pin, val); return Bool(val[]);)

		$func_get(pin::Pin, val::Ref{Cbool}) = $func_get(pin.module_, pin.index, val)
		$func_get(pin::Pin) = $func_get(pin.module_, pin.index)
	end

	cfunc_get = "b0_dio_multiple_"*n*"_get"
	cfunc_set = "b0_dio_multiple_"*n*"_set"

	@eval begin
		$func_set(mod::Ptr{Dio}, pins::Ptr{Cuint}, size::Csize_t, val::Cbool) =
			act(ccall(($cfunc_set, "libbox0"), ResultCode,
				(Ptr{Dio}, Ptr{Cuint}, Csize_t, Cbool), mod, pins, size, val))

		#NOTE: remove in future if julia convert Bool and Cbool transparently
		$func_set(mod::Ptr{Dio}, pins::Ptr{Cuint}, size::Csize_t, val::Bool) =
			$func_set(mod, pins, size, Cbool(val))

		$func_set(mod::Ptr{Dio}, pins::Array{Cuint}, val::Bool) =
			$func_set(mod, pointer(pins), Csize_t(length(pins)), val)

		$func_set(pin_group::PinGroup, val::Cbool) =
			$func_set(pin_group.module_, pin_group.indexes, val)

		#NOTE: remove in future if julia convert Bool and Cbool transparently
		$func_set(pin_group::PinGroup, val::Bool) = $func_set(pin_group, Cbool(val))

		# ---

		$func_get(mod::Ptr{Dio}, pins::Ptr{Cuint}, values::Ptr{Cbool}, size::Csize_t) =
			act(ccall(($cfunc_get, "libbox0"), ResultCode,
				(Ptr{Dio}, Ptr{Cuint}, Ptr{Cbool}, Csize_t), mod, pins, values, size))

		$func_get(mod::Ptr{Dio}, pins::Array{Cuint}, values::Array{Cbool}) = (
			@assert length(pins) == length(vals);
			$func_get(mod, pointer(pins), pointer(values), Csize_t(length(pins)))
		)

		$func_get(pin_group::PinGroup, values::Ptr{Cbool}, size::Csize_t) = (
			@assert length(pin_group.indexes) == size;
			$func_get(pin_group.module_, pointer(pin_group.indexes), values, size)
		)

		$func_get(pin_group::PinGroup, values::Array{Cbool}) =
			$func_get(pin_group.module_, pin_group.indexes, values)
	end

	cfunc_get = "b0_dio_all_"*n*"_get"
	cfunc_set = "b0_dio_all_"*n*"_set"

	@eval begin
		$func_set(mod::Ptr{Dio}, val::Cbool) =
			act(ccall(($cfunc_set, "libbox0"), ResultCode,
				(Ptr{Dio}, Cbool), mod, val))

		#NOTE: remove in future if julia convert Bool and Cbool transparently
		$func_set(mod::Ptr{Dio}, val::Bool) = $func_set(mod, Cbool(val))

		# ---

		# using this function can be dangerous.
		# it assume that the array length is equal to number of pins
		$func_get(mod::Ptr{Dio}, values::Ptr{Cbool}) =
			act(ccall(($cfunc_get, "libbox0"), ResultCode,
				(Ptr{Dio}, Ptr{Cbool}), mod, values))

		$func_get(mod::Ptr{Dio}, values::Array{Cbool}) = (
			@assert length(val) >= mod.count.value;
			$func_get(mod, pointer(values))
		)
	end
end

#special case: value toggle
value_toggle(mod::Ptr{Dio}, pin::Cuint) =
	act(ccall(("b0_dio_value_toggle", "libbox0"), ResultCode,
		(Ptr{Dio}, Cuint), mod, pin))

value_toggle(mod::Ptr{Dio}, pins::Ptr{Cuint}, size::Csize_t) =
	act(ccall(("b0_dio_multiple_value_toggle", "libbox0"), ResultCode,
		(Ptr{Dio}, Ptr{Cuint}, Csize_t), mod, pins, size))

value_toggle(mod::Ptr{Dio}, pins::Array{Cuint}) =
	value_toggle(mod, pointer(pins), Csize_t(length(pins)))

value_toggle(mod::Ptr{Dio}) =
	act(ccall(("b0_dio_all_value_toggle", "libbox0"), ResultCode, (Ptr{Dio}, ), dio))

value_toggle(pin::Pin) = value_toggle(pin.module_, pin.index)

value_toggle(pin_group::PinGroup) = value_toggle(pin_group.module_, pin_group.indexes)

#easy to use (single)
input(mod::Ptr{Dio}, pin::Cuint) = dir_set(mod, pin, INPUT)
output(mod::Ptr{Dio}, pin::Cuint) = dir_set(mod, pin, OUTPUT)
high(mod::Ptr{Dio}, pin::Cuint) = value_set(mod, pin, HIGH)
low(mod::Ptr{Dio}, pin::Cuint) = value_set(mod, pin, LOW)
toggle(mod::Ptr{Dio}, pin::Cuint) = value_toggle(mod, pin)
enable(mod::Ptr{Dio}, pin::Cuint) = hiz_set(mod, pin, DISABLE)
disable(mod::Ptr{Dio}, pin::Cuint) = hiz_set(mod, pin, ENABLE)

#easy to use (multiple)
input(mod::Ptr{Dio}, pins::Array{Cuint}) = dir_set(mod, pins, INPUT)
output(mod::Ptr{Dio}, pins::Array{Cuint}) = dir_set(mod, pins, OUTPUT)
high(mod::Ptr{Dio}, pins::Array{Cuint}) = value_set(mod, pins, HIGH)
low(mod::Ptr{Dio}, pins::Array{Cuint}) = value_set(mod, pins, LOW)
toggle(mod::Ptr{Dio}, pins::Array{Cuint}) = value_toggle(mod, pins)
enable(mod::Ptr{Dio}, pins::Array{Cuint}) = hiz_set(mod, pins, DISABLE)
disable(mod::Ptr{Dio}, pins::Array{Cuint}) = hiz_set(mod, pins, ENABLE)

#easy to use (all)
input(mod::Ptr{Dio}) = dir_set(mod, INPUT)
output(mod::Ptr{Dio}) = dir_set(mod, OUTPUT)
high(mod::Ptr{Dio}) = value_set(mod, HIGH)
low(mod::Ptr{Dio}) = value_set(mod, LOW)
toggle(mod::Ptr{Dio}) = value_toggle(mod)
enable(mod::Ptr{Dio}) = hiz_set(mod, DISABLE)
disable(mod::Ptr{Dio}) = hiz_set(mod, ENABLE)

# easy to use (pin)
input(pin::Pin) = input(pin.module_, pin.index)
output(pin::Pin) = output(pin.module_, pin.index)
high(pin::Pin) = high(pin.module_, pin.index)
low(pin::Pin) = low(pin.module_, pin.index)
toggle(pin::Pin) = toggle(pin.module_, pin.index)
enable(pin::Pin) = enable(pin.module_, pin.index)
disable(pin::Pin) = disable(pin.module_, pin.index)

#easy to use (pin group)
input(pin_group::PinGroup) = input(pin_group.module_, pin_group.indexes)
output(pin_group::PinGroup) = output(pin_group.module_, pin_group.indexes)
high(pin_group::PinGroup) = high(pin_group.module_, pin_group.indexes)
low(pin_group::PinGroup) = low(pin_group.module_, pin_group.indexes)
toggle(pin_group::PinGroup) = toggle(pin_group.module_, pin_group.indexes)
enable(pin_group::PinGroup) = enable(pin_group.module_, pin_group.indexes)
disable(pin_group::PinGroup) = disable(pin_group.module_, pin_group.indexes)
