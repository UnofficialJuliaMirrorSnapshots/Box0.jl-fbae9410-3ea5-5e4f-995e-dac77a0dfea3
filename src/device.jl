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

export close, ping, manuf, name, serial

close(dev::Ptr{Device}) = act(ccall(("b0_device_close", "libbox0"),
		ResultCode, (Ptr{Device}, ), dev))

ping(dev::Ptr{Device}) = act(ccall(("b0_device_ping", "libbox0"),
		ResultCode, (Ptr{Device}, ), dev))

name(dev::Ptr{Device}) = unsafe_string(deref(dev).name)
manuf(dev::Ptr{Device}) = unsafe_string(deref(dev).manuf)
serial(dev::Ptr{Device}) = unsafe_string(deref(dev).serial)

# internal work
module_offset_valid(dev::Ptr{Device}, i::Csize_t) = (i <= deref(dev).modules_len)
unsafe_get_module(dev::Ptr{Device}, i::Csize_t) = unsafe_load(deref(dev).modules, i)
function safe_get_module(dev::Ptr{Device}, i::Csize_t)
	if !module_offset_valid(dev, i)
		throw(ArgumentError("index out of range"))
	end
	return unsafe_get_module(dev, i)
end

# just for ease
Base.length(dev::Ptr{Device}) = deref(dev).modules_len

# device iterator
Base.start(dev::Ptr{Device}) = one(Csize_t)
Base.next(dev::Ptr{Device}, state::Csize_t) =
	(unsafe_get_module(dev, state), state + one(state))
Base.done(dev::Ptr{Device}, state::Csize_t) = (! module_offset_valid(dev, state))
