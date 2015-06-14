#!/usr/bin/env ruby

outfile = File.open("./novData.yml", "w")
for i in 1..30
	outfile.puts("fdw_pivot_2012_"+(183+i).to_s+":")
	outfile.puts("  field: field_for_pivot_2012")
	outfile.puts("  date: 2012-11-"+i.to_s)
	outfile.puts("  ref_et: 0.15")
	outfile.puts("  rain: 0.0")
	outfile.puts("  leaf_area_index: 0.5")
	outfile.puts("  irrigation: 0.0")
	outfile.puts("end")
	outfile.puts("")
end
outfile.flush
outfile.close