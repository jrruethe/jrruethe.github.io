#!/usr/bin/env ruby

# file-to-address.rb
# Copyright (C) 2015 Joe Ruether jrruethe@gmail.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

require 'digest'

# Get the filename
filename = ARGV[0]

# Hash the file
hash = Digest::SHA256.hexdigest File.read filename

# Take only the first 20 bytes
hash = hash[0..39]

# Prepend 0x00 to the hash
hash = "00" + hash

# Calculate the checksum
checksum = Digest::SHA256.hexdigest [hash].pack("H*")
checksum = Digest::SHA256.hexdigest [checksum].pack("H*")

# Pull out the first 4 bytes
checksum = checksum[0..7]

def encode_base58(hex)
   int_val = hex.to_i(16)
   alpha = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
   base58_val, base = '', alpha.size
   while int_val > 0
      int_val, remainder = int_val.divmod(base)
      base58_val = alpha[remainder] + base58_val
   end
   leading_zero_bytes  = (hex.match(/^([0]+)/) ? $1 : '').size / 2
   ("1"*leading_zero_bytes) + base58_val
end

# Generate the address
address = encode_base58(hash + checksum)

puts address

