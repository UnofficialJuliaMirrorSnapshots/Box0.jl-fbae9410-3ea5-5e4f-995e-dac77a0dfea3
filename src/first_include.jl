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

export Device, Module_, ModuleType, Backend

# these has to be before everything because julia do not
#  support forward declaration
# see: https://github.com/JuliaLang/julia/issues/269

abstract type Backend end

immutable _Device{M}
	modules_len::Csize_t
	modules::Ptr{Ptr{M}}
	name::Ptr{UInt8}
	manuf::Ptr{UInt8}
	serial::Ptr{UInt8}
	_backend_data::Ptr{Void}
	_frontend_data::Ptr{Void}
	_backend::Ptr{Backend}
end

const ModuleType = Cint

immutable Module_
	type_::ModuleType
	index::Cint
	name::Ptr{UInt8}
	device::Ptr{_Device{Module_}}
	_backend_data::Ptr{Void}
	_frontend_data::Ptr{Void}
end

const Device = _Device{Module_}

const RefType = Cint
VOLTAGE = RefType(0)
CURRENT = RefType(1)
