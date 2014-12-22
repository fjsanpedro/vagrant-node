
require 'pp'

module Vagrant
module Node
module Util

	class HwFunctions
		def self.get_mem_values

			mem = []

			mem_file = "/proc/meminfo"
			mem_values = IO.readlines(mem_file) 

			mem[0] = (mem_values[0].split[1].to_i / 1024.0).round(2) #Converting to MB
			mem[1] = (mem_values[1].split[1].to_i / 1024.0).round(2) #Converting to MB

			mem

		end

		
	end

end
end
end