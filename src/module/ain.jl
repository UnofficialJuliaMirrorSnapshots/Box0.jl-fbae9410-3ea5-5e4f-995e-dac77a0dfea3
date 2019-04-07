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

export Ain
export mod, open, close
export snapshot_prepare, snapshot_start, snapshot_stop
export stream_prepare, stream_start, stream_stop
export bitsize_speed_get, bitsize_speed_set, chan_seq_set, chan_seq_get
export AIN_CAPAB_FORMAT_2COMPL, AIN_CAPAB_FORMAT_BINARY
export AIN_CAPAB_ALIGN_LSB, AIN_CAPAB_ALIGN_MSB
export AIN_CAPAB_ENDIAN_LITTLE, AIN_CAPAB_ENDIAN_BIG

const AinCapab = Cint
AIN_CAPAB_FORMAT_2COMPL = AinCapab(1 << 0)
AIN_CAPAB_FORMAT_BINARY = AinCapab(0 << 0)
AIN_CAPAB_ALIGN_LSB = AinCapab(0 << 1)
AIN_CAPAB_ALIGN_MSB = AinCapab(1 << 1)
AIN_CAPAB_ENDIAN_LITTLE = AinCapab(0 << 2)
AIN_CAPAB_ENDIAN_BIG = AinCapab(1 << 2)

immutable AinLabel
	chan::Ptr{Ptr{UInt8}}
end

immutable AinRef
	high::Float64
	low::Float64
	type_::RefType
end

immutable AinBitsizeSpeedsSpeed
	values::Ptr{Culong}
	count::Csize_t
end

immutable AinBitsizeSpeeds
	bitsize::Cuint
	speed::AinBitsizeSpeedsSpeed
end

immutable AinModeBitsizeSpeeds
	values::AinBitsizeSpeeds
	count::Csize_t
end

immutable Ain
	header::Module_
	chan_count::Cuint
	buffer_size::Csize_t
	capab::AinCapab
	label::AinLabel
	ref::AinRef
	stream::AinModeBitsizeSpeeds
	snapshot::AinModeBitsizeSpeeds
end

bitsize_speed_set(mod::Ptr{Ain}, bitsize::Cuint, speed::Culong) =
	act(ccall(("b0_ain_bitsize_speed_set", "libbox0"), ResultCode,
			(Ptr{Ain}, Cuint, Culong), mod, bitsize, speed))

bitsize_speed_get(mod::Ptr{Ain}, bitsize::Ptr{Cuint}, speed::Ptr{Culong}) =
	act(ccall(("b0_ain_bitsize_speed_get", "libbox0"), ResultCode,
			(Ptr{Ain}, Ptr{Cuint}, Ptr{Culong}), mod, bitsize, speed))

chan_seq_set(mod::Ptr{Ain}, values::Ptr{Cuint}, count::Csize_t) =
	act(ccall(("b0_ain_chan_seq_set", "libbox0"), ResultCode,
				(Ptr{Ain}, Ptr{Cuint}, Csize_t), mod, values, count))

chan_seq_set(mod::Ptr{Ain}, values::Array{Cuint}) =
		chan_seq_set(mod, pointer(values), Csize_t(length(values)))

chan_seq_get(mod::Ptr{Ain}, values::Ptr{Cuint}, count::Ref{Csize_t}) =
	act(ccall(("b0_ain_chan_seq_get", "libbox0"), ResultCode,
				(Ptr{Ain}, Ptr{Cuint}, Ptr{Csize_t}), mod, values, count))

#stream
stream_prepare(mod::Ptr{Ain}) =
	act(ccall(("b0_ain_stream_prepare", "libbox0"), ResultCode, (Ptr{Ain}, ), mod))

stream_start(mod::Ptr{Ain}) =
	act(ccall(("b0_ain_stream_start", "libbox0"), ResultCode, (Ptr{Ain}, ), mod))

for (t::Type, s::String) in ((Void, ""), (Float32, "_float"), (Float64, "_double"))
	func = "b0_ain_stream_write"*s
	@eval begin
		stream_start(mod::Ptr{Ain}, data::Ptr{$t}, count::Csize_t,
					actual_count::Ptr{Csize_t} = C_NULL(Csize_t)) =
			act(ccall(($func, "libbox0"), ResultCode,
				(Ptr{Ain}, Ptr{$t}, Csize_t, Ptr{Csize_t}), mod, data, count, actual_count))
	end
end

stream_read{T}(mod::Ptr{Ain}, samples::Ptr{T}, count::Integer) =
	stream_read(mod, samples, Csize_t(count))

stream_read{T}(mod::Ptr{Ain}, samples::Array{T}) =
	stream_read(mod, pointer(samples), length(samples))

stream_stop(mod::Ptr{Ain}) =
	act(ccall(("b0_ain_stream_stop", "libbox0"), ResultCode, (Ptr{Ain}, ), mod))

#snapshot
snapshot_prepare(mod::Ptr{Ain}) =
	act(ccall(("b0_ain_snapshot_prepare", "libbox0"), ResultCode, (Ptr{Ain}, ), mod))

for (t::Type, s::String) in ((Void, ""), (Float32, "_float"), (Float64, "_double"))
	func = "b0_ain_snapshot_start"*s
	@eval begin
		snapshot_start(mod::Ptr{Ain}, data::Ptr{$t}, count::Csize_t) =
			act(ccall(($func, "libbox0"), ResultCode,
				(Ptr{Ain}, Ptr{$t}, Csize_t), mod, data, count))
	end
end

snapshot_stop(mod::Ptr{Ain}) =
	act(ccall(("b0_ain_snapshot_stop", "libbox0"), ResultCode, (Ptr{Ain}, ), mod))
