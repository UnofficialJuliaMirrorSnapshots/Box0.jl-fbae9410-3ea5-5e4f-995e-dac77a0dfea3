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

export ResultException
export name, explain

const ResultCode = Cint

immutable ResultException <: Exception
	value::ResultCode
end

# libbox0 calls.
# not intended for direct use
name(r::ResultCode) =
	ccall(("b0_result_name", "libbox0"), Ptr{UInt8}, (ResultCode, ), r)
explain(r::ResultCode) =
	ccall(("b0_result_explain", "libbox0"), Ptr{UInt8}, (ResultCode, ), r)

name(r::ResultException) = unsafe_string(name(r.value))
explain(r::ResultException) = unsafe_string(explain(r.value))

showerror(io::IO, r::ResultException) = print(io, name(r), ": ", explain(r))

act(r::ResultCode) = (r < 0 ? throw(ResultException(r)) : nothing)

const OK = ResultCode(0)
const ERR_UNAVAIL = ResultCode(-16)
