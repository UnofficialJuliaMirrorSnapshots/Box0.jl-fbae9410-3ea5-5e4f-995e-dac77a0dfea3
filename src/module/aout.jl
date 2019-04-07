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

export Aout
export snapshot_prepare, snapshot_start, snapshot_stop
export stream_prepare, stream_start, stream_stop, stream_write
export bitsize_speed_get, bitsize_speed_set, chan_seq_set, chan_seq_get
export repeat_get, repeat_set
export AIN_CAPAB_FORMAT_2COMPL, AIN_CAPAB_FORMAT_BINARY
export AIN_CAPAB_ALIGN_LSB, AIN_CAPAB_ALIGN_MSB
export AIN_CAPAB_ENDIAN_LITTLE, AIN_CAPAB_ENDIAN_BIG
export AIN_CAPAB_REPEAT

const AoutCapab = Cint
AIN_CAPAB_FORMAT_2COMPL = AoutCapab(1 << 0)
AIN_CAPAB_FORMAT_BINARY = AoutCapab(0 << 0)
AIN_CAPAB_ALIGN_LSB = AoutCapab(0 << 1)
AIN_CAPAB_ALIGN_MSB = AoutCapab(1 << 1)
AIN_CAPAB_ENDIAN_LITTLE = AoutCapab(0 << 2)
AIN_CAPAB_ENDIAN_BIG = AoutCapab(1 << 2)
AIN_CAPAB_REPEAT = AoutCapab(1 << 3)

immutable AoutLabel
	chan::Ptr{Ptr{UInt8}}
end

immutable AoutRef
	high::Float64
	low::Float64
	type_::RefType
end

immutable AoutBitsizeSpeedsSpeed
	values::Ptr{Culong}
	count::Csize_t
end

immutable AoutBitsizeSpeeds
	bitsize::Cuint
	speed::AoutBitsizeSpeedsSpeed
end

immutable AoutModeBitsizeSpeeds
	values::AoutBitsizeSpeeds
	count::Csize_t
end

immutable Aout
	header::Module_
	chan_count::Cuint
	buffer_size::Csize_t
	capab::AoutCapab
	label::AoutLabel
	ref::AoutRef
	stream::AoutModeBitsizeSpeeds
	snapshot::AoutModeBitsizeSpeeds
end

bitsize_speed_set(mod::Ptr{Aout}, bitsize::Cuint, speed::Culong) =
	act(ccall(("b0_aout_bitsize_speed_set", "libbox0"), ResultCode,
			(Ptr{Aout}, Cuint, Culong), mod, bitsize, speed))

bitsize_speed_get(mod::Ptr{Aout}, bitsize::Ptr{Cuint}, speed::Ptr{Culong}) =
	act(ccall(("b0_aout_bitsize_speed_get", "libbox0"), ResultCode,
			(Ptr{Aout}, Ptr{Cuint}, Ptr{Culong}), mod, bitsize, speed))

chan_seq_set(mod::Ptr{Aout}, values::Ptr{Cuint}, count::Csize_t) =
	act(ccall(("b0_aout_chan_seq_set", "libbox0"), ResultCode,
				(Ptr{Aout}, Ptr{Cuint}, Csize_t), mod, values, count))

chan_seq_get(mod::Ptr{Aout}, values::Ptr{Cuint}, count::Ref{Csize_t}) =
	act(ccall(("b0_aout_chan_seq_get", "libbox0"), ResultCode,
				(Ptr{Aout}, Ptr{Cuint}, Ptr{Csize_t}), mod, values, count))

repeat_set(mod::Ptr{Aout}, value::Culong) =
	act(ccall(("b0_aout_repeat_set", "libbox0"), ResultCode,
			(Ptr{Aout}, Culong), mod, value))

repeat_get(mod::Ptr{Aout}, value::Ptr{Culong}) =
	act(ccall(("b0_aout_repeat_get", "libbox0"), ResultCode,
			(Ptr{Aout}, Culong), mod, value))

#stream
stream_prepare(mod::Ptr{Aout}) =
	act(ccall(("b0_aout_stream_prepare", "libbox0"), ResultCode, (Ptr{Aout}, ), mod))

stream_start(mod::Ptr{Aout}) =
	act(ccall(("b0_aout_stream_start", "libbox0"), ResultCode, (Ptr{Aout}, ), mod))

stream_stop(mod::Ptr{Aout}) =
	act(ccall(("b0_aout_stream_stop", "libbox0"), ResultCode, (Ptr{Aout}, ), mod))

for (t::Type, s::String) in ((Void, ""), (Float32, "_float"), (Float64, "_double"))
	func = "b0_aout_stream_write"*s
	@eval begin
		stream_write(mod::Ptr{Aout}, data::Ptr{$t}, count::Csize_t) =
			act(ccall(($func, "libbox0"), ResultCode,
				(Ptr{Aout}, Ptr{$t}, Csize_t), mod, data, count))
	end
end

stream_write{T}(mod::Ptr{Aout}, data::Ptr{T}, count::Integer) =
	stream_write(mod, data, Csize_t(count))

stream_write{T}(mod::Ptr{Aout}, data::Array{T}) =
	stream_write(mod, pointer(data), length(data))

#snapshot
snapshot_prepare(mod::Ptr{Aout}) =
	act(ccall(("b0_aout_snapshot_prepare", "libbox0"), ResultCode, (Ptr{Aout}, ), mod))

snapshot_stop(mod::Ptr{Aout}) =
	act(ccall(("b0_aout_snapshot_stop", "libbox0"), ResultCode, (Ptr{Aout}, ), mod))

for (t::Type, s::String) in ((Void, ""), (Float32, "_float"), (Float64, "_double"))
	func = "b0_aout_snapshot_start"*s
	@eval begin
		snapshot_start(mod::Ptr{Aout}, data::Ptr{$t}, count::Csize_t) =
			act(ccall(($func, "libbox0"), ResultCode,
				(Ptr{Aout}, Ptr{$t}, Csize_t), mod, data, count))
	end
end
