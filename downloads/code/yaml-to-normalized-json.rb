#!/usr/bin/env ruby

# yaml-to-normalized-json.rb
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

require 'yaml'
require 'json'

class String

   # Add a snakecase function to the String class
   def snakecase
      self.gsub(/[:\-]/, "").gsub(" ", "_").downcase
   end
   
   # Strip spaces and downcase
   def normalize
      self.gsub(/[: \-]/, "").downcase
   end
  
   # Check if a string is a hex value
   def is_hex?
      /^[0-9A-F]+$/i === self.normalize
   end
end

# Load the yaml file
h = YAML.load_file ARGV[0]

# Convert all keys to snakecase
h = Hash[h.map{|k, v| [k.snakecase, v] }]

# Normalize all hex values
h.each do |k, v|
   if v.is_a?(String) && v.is_hex?
      h[k] = v.normalize
   end
end

# Sort the keys
h = Hash[*h.sort.flatten]

# Pretty print
puts JSON.pretty_generate(h)

