#!/usr/bin/env ruby

# Get the address
address = ARGV[0]
    
def decode_base58(base58_val)
   alpha = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
   int_val, base = 0, alpha.size
   base58_val.reverse.each_char.with_index do |char,index|
      raise ArgumentError, 'Value not a valid Base58 String.' unless char_index = alpha.index(char)
      int_val += char_index*(base**index)
   end
   s = int_val.to_s(16)
   s = (s.bytesize.odd? ? '0'+s : s)
   s = '' if s == '00'
   leading_zero_bytes = (base58_val.match(/^([1]+)/) ? $1 : '').size
   s = ("00"*leading_zero_bytes) + s  if leading_zero_bytes > 0
   s
end

# Get the hex payload
payload = decode_base58(address)

# Print out the first 20 bytes of the sha256 hash
puts payload[2..41]

