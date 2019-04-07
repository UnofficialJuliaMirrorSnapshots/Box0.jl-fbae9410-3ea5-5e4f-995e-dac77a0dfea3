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

export I2c, I2cTask, I2cTaskFlags
export I2cTaskWrite, I2cTaskRead
export master_prepare, master_start, master_stop
export master_write8_read, master_write_read, master_read, master_write, master_slave_detect, master_slave_id
export I2C_TASK_LAST, I2C_TASK_WRITE, I2C_TASK_READ, I2C_TASK_DIR_MASK
export I2C_VERSION_SM, I2C_VERSION_FM, I2C_VERSION_HS, I2C_VERSION_HS_CLEANUP1
export I2C_VERSION_FMPLUS, I2C_VERSION_UFM, I2C_VERSION_VER5, I2C_VERSION_VER6

const I2cTaskFlags = Cint
I2C_TASK_LAST = I2cTaskFlags(1 << 0) # Last task to execute
I2C_TASK_WRITE = I2cTaskFlags(0 << 1) # Perform write
I2C_TASK_READ = I2cTaskFlags(1 << 1) # Perform read
I2C_TASK_DIR_MASK = I2cTaskFlags(1 << 1)

const I2cVersion = Cint
I2C_VERSION_SM = I2cVersion(0)
I2C_VERSION_FM = I2cVersion(1)
I2C_VERSION_HS = I2cVersion(2)
I2C_VERSION_HS_CLEANUP1 = I2cVersion(3)
I2C_VERSION_FMPLUS = I2cVersion(4)
I2C_VERSION_UFM = I2cVersion(5)
I2C_VERSION_VER5 = I2cVersion(6)
I2C_VERSION_VER6 = I2cVersion(7)

immutable I2cTask
	flags::I2cTaskFlags # Transfer flags
	addr::UInt8  # Slave address
    version::I2cVersion # Version
	data::Ptr{Void} # Pointer to data
	count::Csize_t # Number of bytes to transfer
end

I2cTask{T}(flags::I2cTaskFlags, addr::UInt8, data::Array{T}) =
	I2cTask(flags, addr, Ptr{Void}(pointer(data)), Csize_t(sizeof(data)))

function I2cTaskRead{T}(addr::UInt8, data::Array{T}; last::Bool = false)
	flags::I2cTaskFlags = I2C_TASK_READ
	if last
		flags |= I2C_TASK_LAST
	end
	I2cTask(flags, addr, data)
end

function I2cTaskWrite{T}(addr::UInt8, data::Array{T}; last::Bool = false)
	flags::I2cTaskFlags = I2C_TASK_WRITE
	if last
		flags |= I2C_TASK_LAST
	end
	I2cTask(flags, addr, data)
end

immutable I2cLabel
	sck::Ptr{UInt8}
	sda::Ptr{UInt8}
end

immutable I2cRef
	high::Float64
	low::Float64
end

immutable I2cVersionList
	values::Ptr{I2cVersion}
	count::Csize_t
end

immutable I2c
	header::Module_
	label::I2cLabel
	version::I2cVersionList
	ref::I2cRef
end

master_prepare(mod::Ptr{I2c}) =
	act(ccall(("b0_i2c_master_prepare", "libbox0"), ResultCode, (Ptr{I2c}, ), mod))

master_start(mod::Ptr{I2c}, tasks::Ref{I2cTask}, failed_task_index::Ref{Cint},
		failed_task_ack::Ref{Cint}) =
	act(ccall(("b0_i2c_master_start", "libbox0"), ResultCode,
		(Ptr{I2c}, Ptr{I2cTask}, Ptr{Cint}, Ptr{Cint}),
		mod, tasks, failed_task_index, failed_task_ack))

function master_start(mod::Ptr{I2c}, tasks::Ref{I2cTask})
	failed_task_index = Ref{Cint}(0)
	failed_task_ack = Ref{Cint}(0)
	start(mod, tasks, failed_task_index, failed_task_ack)
	return failed_task_index[], failed_task_ack[]
end

master_start(mod::Ptr{I2c}, tasks::Array{I2cTask}) = start(mod, pointer(tasks))
master_start(mod::Ptr{I2c}, task::I2cTask) = (
	(task.flags & I2C_TASK_LAST) != 0 || error("LAST flag missing on task");
	start(mod, Ref(task))
)

master_stop(mod::Ptr{I2c}) =
	act(ccall(("b0_i2c_master_stop", "libbox0"), ResultCode, (Ptr{I2c}, ), mod))

immutable I2cSugarArg
	addr::UInt8
	version::I2cVersion
end

master_read(mod::Ptr{I2c}, arg::Ref{I2cSugarArg}, data::Ref{Void}, count::Csize_t) =
	act(ccall(("b0_i2c_master_read", "libbox0"), ResultCode,
		(Ptr{I2c}, Ptr{I2cSugarArg}, Ptr{Void}, Csize_t), mod, arg, data, count))

master_read{T}(mod::Ptr{I2c}, arg::I2cSugarArg, data::Array{T}) =
	master_read(mod, Ref(arg), Ptr{Void}(pointer(data)), Csize_t(sizeof(data)))

master_write8_read(mod::Ptr{I2c}, arg::Ref{I2cSugarArg}, write::UInt8,
		read_data::Ptr{Void}, read_count::Csize_t) =
	act(ccall(("b0_i2c_master_write8_read", "libbox0"), ResultCode,
		(Ptr{I2c}, Ptr{I2cSugarArg}, UInt8, Ptr{Void}, Csize_t),
		mod, arg, write, read_data, read_count))

master_write8_read{T}(mod::Ptr{I2c}, arg::I2cSugarArg, write::UInt8, read::Array{T}) =
	master_write8_read(mod, Ref(arg), write, Ptr{Void}(pointer(read)), Csize_t(sizeof(read)))

master_write_read(mod::Ptr{I2c}, arg::Ref{I2cSugarArg}, write_data::Ptr{Void},
		write_count::Csize_t, read_data::Ptr{Void}, read_count::Csize_t) =
	act(ccall(("b0_i2c_master_write_read", "libbox0"), ResultCode,
		(Ptr{I2c}, Ptr{I2cSugarArg}, Ptr{Void}, Csize_t, Ptr{Void}, Csize_t),
		mod, arg, write, write_data, write_count, read_data, read_count))

master_write_read{T,U}(mod::Ptr{I2c}, arg::I2cSugarArg, write::Array{T}, read::Array{U}) =
	master_write_read(mod, Ref(arg), Ptr{Void}(pointer(write)), Csize_t(sizeof(read)),
		Ptr{Void}(pointer(read)), Csize_t(sizeof(read)))

master_write(mod::Ptr{I2c}, arg::Ref{I2cSugarArg}, data::Ptr{Void}, count::Csize_t) =
	act(ccall(("b0_i2c_master_write", "libbox0"), ResultCode,
		(Ptr{I2c}, Ptr{I2cSugarArg}, Ptr{Void}, Csize_t), mod, arg, data, count))

master_write{T}(mod::Ptr{I2c}, arg::I2cSugarArg, data::Array{T}) =
	master_write(mod, Ref(arg), Ptr{Void}(pointer(data)), Csize_t(sizeof(data)))

master_slave_id(mod::Ptr{I2c}, arg::Ref{I2cSugarArg},
		manuf::Ref{UInt16}, part::Ref{UInt16}, rev::Ref{UInt8}) =
	act(ccall(("b0_i2c_master_slave_id", "libbox0"), ResultCode,
		(Ptr{I2c}, Ptr{I2cSugarArg}, Ref{UInt16}, Ref{UInt8}, Ref{UInt8}),
		mod, arg, manuf, part, rev))

function master_slave_id(mod::Ptr{I2c}, arg::I2cSugarArg)
	manuf = Ref{UInt16}(0)
	part = Ref{UInt16}(0)
	rev = Ref{UInt8}(0)
	master_slave_id(mod, ptr(arg), manuf, part, rev)
	return manuf, part, rev
end

master_slave_detect(mod::Ptr{I2c}, arg::Ref{I2cSugarArg}, detected::Ref{Cbool}) =
	act(ccall(("b0_i2c_master_slave_detect", "libbox0"), ResultCode,
		(Ptr{I2c}, Ptr{I2cSugarArg}, Ptr{Cbool}), mod, arg, detected))

function master_slave_detect(mod::Ptr{I2c}, arg::I2cSugarArg)
	val = Ref{Cbool}(0)
	master_slave_detect(mod, ptr(arg), val)
	return Bool(val[])
end

# TODO: master slaves detect
