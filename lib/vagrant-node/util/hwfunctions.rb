
require 'pp'

module Vagrant
module Node
module Util

	class HwFunctions
		MAJOR_SATA = 8
		MAJOR_IDE = 3
		MAJOR_FIELD = 0
		MINOR_FIELD = 1
		NAME_FIELD = 2
		def self.get_mem_values

			mem = []

			mem_file = "/proc/meminfo"
			mem_values = IO.readlines(mem_file) 

			
			mem[0] = (mem_values[0].split[1].to_i / 1024.0).round(2) #Converting to MB
			mem[1] = (mem_values[1].split[1].to_i / 1024.0).round(2) #Converting to MB

			mem

		end

		def self.get_disk_values

			disk = []

			stat_file = "/proc/diskstats"


			IO.readlines(stat_file).each do |line|
				major_number = line.split[MAJOR_FIELD].to_i
				minor_number = line.split[MINOR_FIELD].to_i
				
				if (((major_number==MAJOR_SATA) || (major_number==MAJOR_IDE)) && minor_number!=0)
					#In this point you have all single disk partitions
					#But we only want mounted ones					
					resout= `df -h`					
					resout.split("\n").each do |line1|
						if (line1.split[0]=="/dev/"+line.split[NAME_FIELD])
							entry =[]
							entry[0] = line.split[NAME_FIELD]
							entry[1] = line1.split[1]
							entry[2] = line1.split[3]
							entry[3] = line1.split[4]
							disk << {:partition=>"/dev/"+line.split[NAME_FIELD],
									:total=>line1.split[1],
									:free=>line1.split[3],
									:freepercent=>line1.split[4]}
							# disk.push entry
						end
					end
					

				end
			end

			
			
			disk

		end
		
	end

end
end
end