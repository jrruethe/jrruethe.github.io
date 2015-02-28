#!/usr/bin/env ruby

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

