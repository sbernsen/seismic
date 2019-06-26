#=
MASW of an active source survey
=# 

##### -------------------------------------------------------------------- #####
# Load Modules
using SAC, DSP, RCall

# Read in the ordered list of filenames for each stations 
station_filenames = readdlm("../transverse_stations.txt")
station_indices = Int.( station_filenames[:,2]  )
txrx_distance = float.(station_filenames[:,3])

station_filenames = station_filenames[:,1]



##### -------------------------------------------------------------------- #####
# We need Δt and Δx. We can get Δt from the SAC header but for now we'll define Δx 
dx = mean( diff(txrx_distance) )

# Let's load the data into an array 
# Read in the first data file to allocate space 
ts = SAC.read(station_filenames[1])
Δt = ts.delta
ts = ts.t

# Initialize and define constants and vectors
m = length(ts) 
n = length(station_filenames) 


wiggles = zeros(m, n) 
wiggles[:,1] = ts

for i in 2:n
	ts = SAC.read(station_filenames[i])
	wiggles[:,i] = ts.t
	
end


time_vec = collect(0:(m-1)).*ts.delta

R"""
source("../plotting_functions.R")

line_fill <- c("green4", "grey")
main_col <- "white"

png("wiggle_plot.png", width = 4, height = 8, units = "in", res = 100)
plot_geophone_wiggles( $time_vec[1:700], $wiggles[1:700,], line_fill, TRUE, main_col)
dev.off()
"""