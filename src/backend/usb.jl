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

module Usb

import Box0: Device, act, ResultCode

export open_supported

function open_supported()
	dev = Ref{Ptr{Device}}(0)
	act(ccall(("b0_usb_open_supported", "libbox0"), ResultCode, (Ref{Ptr{Device}}, ), dev))
	return dev[]
end

end
