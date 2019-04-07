#
# This file is part of Box0.jl.
# Copyright (C) 2015 Kuldeep Singh Dhaka <kuldeep@madresistor.com>
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

export search, name
export DIO, AOUT, AIN, SPI, I2C, PWM, CAN, CEC, CMP, UNIO
export name, index, type_, device

const DIO = ModuleType(1)
const AOUT = ModuleType(2)
const AIN = ModuleType(3)
const SPI = ModuleType(4)
const I2C = ModuleType(5)
const PWM = ModuleType(6)
const UNIO = ModuleType(7)

name(mod::Ptr{Module_}) = unsafe_string(deref(mod).name)
index(mod::Ptr{Module_}) = deref(mod).index
type_(mod::Ptr{Module_}) = deref(mod).type_
device(mod::Ptr{Module_}) = deref(mod).device

function search(dev::Ptr{Device}, type_::ModuleType, index::Integer)
	mod = Ref{Ptr{Module_}}(C_NULL(Module_))
	act(ccall(("b0_module_search", "libbox0"),
		ResultCode, (Ptr{Device}, Ptr{Ptr{Module_}}, ModuleType, Cint),
		dev, pointer_from_objref(mod), type_, index))
	return mod[]
end

function openable(mod::Ptr{Module_})
	local rc = ccall(("b0_module_openable", "libbox0"),
		ResultCode, (Ptr{Module_}, ), mod)

	if rc == OK
		return true
	elseif rc == ERR_UNAVAIL
		return false
	end

	act(rc)
end
