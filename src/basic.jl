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

export version, log
export NONE, ERROR, WARN, INFO, DEBUG

import Box0: Device

const LogLevel = Cint
const NONE = LogLevel(0)
const ERROR = LogLevel(1)
const WARN = LogLevel(2)
const INFO = LogLevel(3)
const DEBUG = LogLevel(4)

log(dev::Ptr{Device}, val::LogLevel) = act(ccall(("b0_device_log", "libbox0"),
		ResultCode, (Ptr{Device}, LogLevel), dev, val))

type Version
	major::UInt8
	minor::UInt8
	patch::UInt8
end

version_extract(v::Ref{Version} = C_NULL(Version)) =
	ccall(("b0_version_extract", "libbox0"), UInt32, (Ref{Version}, ), v)

Base.convert(::Type{VersionNumber}, v::Version) =
	VersionNumber(v.major, v.minor, v.patch)

function version()
	z = zero(UInt8)
	v = Ref(Version(z, z, z))
	version_extract(v)
	VersionNumber(v[])
end
