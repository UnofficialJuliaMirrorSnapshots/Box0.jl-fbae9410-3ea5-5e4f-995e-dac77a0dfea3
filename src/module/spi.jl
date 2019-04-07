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

export Spi, SpiTask
export master_prepare, master_start, master_stop
export active_state_set, active_state_get, speed_get, speed_set
export SpiTaskFlags, SpiTask
export SpiTaskFd, SpiTaskHdWrite, SpiTaskHdRead
export SPI_TASK_LAST, SPI_TASK_CPHA, SPI_TASK_CPOL
export SPI_TASK_MODE0, SPI_TASK_MODE1, SPI_TASK_MODE2, SPI_TASK_MODE3
export SPI_TASK_FD, SPI_TASK_HD_READ, SPI_TASK_HD_WRITE
export SPI_TASK_MSB_FIRST, SPI_TASK_LSB_FIRST
export SPI_TASK_MODE_MASK, SPI_TASK_DUPLEX_MASK, SPI_TASK_ENDIAN_MASK

const SpiTaskFlags = Cint
SPI_TASK_LAST = SpiTaskFlags(1 << 0) # Last task to execute
SPI_TASK_CPHA = SpiTaskFlags(1 << 1)
SPI_TASK_CPOL = SpiTaskFlags(1 << 2)
SPI_TASK_MODE0 = SpiTaskFlags(0)
SPI_TASK_MODE1 = SPI_TASK_CPHA
SPI_TASK_MODE2 = SPI_TASK_CPOL
SPI_TASK_MODE3 = SPI_TASK_CPOL | SPI_TASK_CPHA
SPI_TASK_FD = SpiTaskFlags(0x0 << 3)
SPI_TASK_HD_READ = SpiTaskFlags(0x3 << 3)
SPI_TASK_HD_WRITE = SpiTaskFlags(0x1 << 3)
SPI_TASK_MSB_FIRST = SpiTaskFlags(0 << 5)
SPI_TASK_LSB_FIRST = SpiTaskFlags(1 << 5)
SPI_TASK_MODE_MASK = SpiTaskFlags(0x3 << 1)
SPI_TASK_DUPLEX_MASK = SpiTaskFlags(0x3 << 3)
SPI_TASK_ENDIAN_MASK = SpiTaskFlags(1 << 5)

immutable SpiTask
	flags::SpiTaskFlags # Task flags
	addr::Cuint # Slave address
	speed::Culong # Speed to use for transfer (0 for fallback)
	bitsize::Cuint # Bitsize to use for transfer
	wdata::Ptr{Void} # Write memory
	rdata::Ptr{Void} # Read memory
	count::Csize_t # Number of data unit
end

function _spi_task_flags(mode::Integer, lsb_first::Bool, last::Bool)
	flags::SpiTaskFlags = (mode & 0x3) << 1
	if lsb_first
		flags |= SPI_TASK_LSB_FIRST
	end
	if last
		flags |= SPI_TASK_LAST
	end
	return flags
end

_spi_task_bitsize(bitsize::Integer, T) = (bitsize > 0 ? bitsize : sizeof(T))

_spi_task_count{T}(count::Integer, data1::Array{T}, data2::Array{T}) =
	(count > 0 ? count : min(length(data1), length(data2)))

_spi_task_count{T}(count::Integer, data::Array{T}) =
	(count > 0 ? count : length(data1))

_bit_to_byte(bits::Integer) = floor((bits + 7) / 8)

function SpiTaskHdRead{T}(addr::Integer, read::Array{T};
		count::Integer=0, speed::Integer=0, bitsize::Integer=0,
		mode::Integer=0, lsb_first::Bool=false, last::Bool=false)
	flags::SpiTaskFlags = _spi_task_flags(mode, lsb_first, last) |
		SPI_TASK_HD_READ
	bitsize::Cuint = _spi_task_bitsize(bitsize, T)
	rdata::Ptr{Void} = Ptr{Void}(pointer(read))
	wdata::Ptr{Void} = C_NULL()
	count::Csize_t = Csize_t(_spi_task_count(count, read))
	@assert(sizeof(read) >= count * _bit_to_byte(bitsize))
	SpiTask(flags, Cuint(addr), speed, bitsize, wdata, rdata, count)
end

function SpiTaskHdWrite{T}(addr::Integer, write::Array{T}; count::UInt=0,
		speed::Integer=0, bitsize::Integer=0, mode::Integer=0,
		lsb_first::Bool=false, last::Bool=false)
	flags::SpiTaskFlags = _spi_task_flags(mode, lsb_first, last) |
		SPI_TASK_HD_WRITE
	bitsize::Cuint = Cuint(_spi_task_bitsize(bitsize, T))
	rdata::Ptr{Void} = C_NULL(Void)
	wdata::Ptr{Void} = Ptr{Void}(pointer(write))
	count::Csize_t = Csize_t(_spi_task_count(count, read))
	@assert(sizeof(write) >= count * _bit_to_byte(bitsize))
	SpiTask(flags, Cuint(addr), speed, bitsize, wdata, rdata, count)
end

function SpiTaskFd{T}(addr::Integer, write::Array{T}, read::Array{T};
		count::Integer=0, speed::Integer=0, bitsize::Integer=0, mode::Integer=0,
		lsb_first::Bool=false, last::Bool=false)
	flags::SpiTaskFlags = _spi_task_flags(mode, lsb_first, last) | SPI_TASK_FD
	bitsize::Cuint = Cuint(_spi_task_bitsize(bitsize, T))
	rdata::Ptr{Void} = Ptr{Void}(pointer(read))
	wdata::Ptr{Void} = Ptr{Void}(pointer(write))
	count::Csize_t = Csize_t(_spi_task_count(count, write, read))
	bytes_req = count * _bit_to_byte(bitsize)
	@assert(sizeof(read) >= bytes_req)
	@assert(sizeof(write) >= bytes_req)
	SpiTask(flags, Cuint(addr), speed, bitsize, wdata, rdata, count)
end

immutable SpiRef
	high::Float64
	low::Float64
	type_::RefType
end

immutable SpiLabel
	sclk::Ptr{UInt8}
	mosi::Ptr{UInt8}
	miso::Ptr{UInt8}
	ss::Ptr{Ptr{UInt8}}
end

immutable SpiBitsize
	values::Ptr{Cuint}
	count::Csize_t
end

immutable SpiSpeed
	values::Ptr{Culong}
	count::Csize_t
end

immutable Spi
	header::Module_
	ss_count::Cuint
	label::SpiLabel
	bitsize::SpiBitsize
	speed::SpiSpeed
	ref::SpiRef
end

master_prepare(mod::Ptr{Spi}) =
	act(ccall(("b0_spi_master_prepare", "libbox0"), ResultCode, (Ptr{Spi}, ), mod))

master_start(mod::Ptr{Spi}, tasks::Ref{SpiTask}, failed_task_index::Ref{Cint},
		failed_task_ack::Ref{Cint}) =
	act(ccall(("b0_spi_master_start", "libbox0"), ResultCode,
		(Ptr{Spi}, Ptr{SpiTask}, Ptr{Cint}, Ptr{Cint}),
		mod, tasks, failed_task_index, failed_task_ack))

function master_start(mod::Ptr{Spi}, tasks::Ref{SpiTask})
	failed_task_index = Ref{Cint}(0)
	failed_task_ack = Ref{Cint}(0)
	master_start(mod, tasks, failed_task_index, failed_task_ack)
	return failed_task_index[], failed_task_ack[]
end

master_start(mod::Ptr{Spi}, tasks::Array{SpiTask}) = start(mod, pointer(tasks))
master_start(mod::Ptr{Spi}, task::SpiTask) = (
	(task.flags & SPI_TASK_LAST) != 0 || error("LAST flag missing on task");
	master_start(mod, Ref(task))
)

master_stop(mod::Ptr{Spi}) =
	act(ccall(("b0_spi_master_stop", "libbox0"), ResultCode, (Ptr{Spi}, ), mod))

active_state_set(mod::Ptr{Spi}, addr::Cuint, val::Cbool) =
	act(ccall(("b0_spi_active_state_set", "libbox0"), ResultCode,
		(Ptr{Spi}, Cuint, Cbool), mod, bSS, val))

#NOTE: remove in future if julia convert Bool and Cbool transparently
active_state_set(mod::Ptr{Spi}, addr::Cuint, val::Bool) =
	active_state(mod, Cuint(addr), Cbool(val))

active_state_get(mod::Ptr{Spi}, addr::Cuint, val::Ref{Cbool}) =
	act(ccall(("b0_spi_active_state_get", "libbox0"), ResultCode,
		(Ptr{Spi}, Cuint, Ref{Cbool}), mod, bSS, val))

function active_state_get(mod::Ptr{Spi}, addr::Cuint)
	val = Ref{Cbool}(0)
	active_state(mod, Cuint(addr), val)
	Bool(val[])
end

speed_set(mod::Ptr{Spi}, speed::Culong) =
	act(ccall(("b0_spi_speed_set", "libbox0"), ResultCode,
			(Ptr{Spi}, Culong), mod, speed))

speed_get(mod::Ptr{Spi}, speed::Ref{Culong}) =
	act(ccall(("b0_spi_speed_get", "libbox0"), ResultCode,
			(Ptr{Spi}, Ptr{Culong}), mod, speed))
