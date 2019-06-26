#=
MASW of an active source survey
=# 

##### -------------------------------------------------------------------- #####
# Load Modules
using SAC, DSP, RCall

# Read in the ordered list of filenames for each stations 
station_filenames = readdlm("../station_list.txt")
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

M = Int(3m/2)

# Define the frequency vector
fnyq=1./(2Δt)
f = collect( linspace(0, fnyq, M) )
ω = 2π.*f

# We need a test velocity vector with small increments
vrt_min = 300 # Shear wave speed in saturated sediments
vrt_max = 3300 # Shear wave speed in granite
vrt = collect(vrt_min:vrt_max)
mxj = length(vrt)
nxj = length(ω)

ϕ = ones(mxj, nxj)
vs = complex.(zeros(mxj, nxj))
ϕ = ϕ.*( 1./collect(vrt_min:vrt_max) )
ϕ = ϕ.*ω' #We still need to multiply by frequency


##### -------------------------------------------------------------------- #####

Y = complex(  zeros( M, n)  )

# Taper, pad and compute the fft of the time series then assign the first column
wt = tukey(m, 0.1)
Y[:,1] = (fft( [ zeros(m); wt.*ts; zeros(m) ] ))[1:M]

# Normalize the magnitude because we want the phase information
Y[:,1] = Y[:,1]./( abs.(Y[:,1]) )

# Multiply ϕ by x_j 
vs = vs + exp.(-im.*ϕ.*txrx_distance[1]).*Y[:,1]'

# Do the same with all of the reciever locations 

for i in 2:n
	ts = SAC.read(station_filenames[i])
	ts = ts.t
	Y[:,i] = (fft( [ zeros(m); wt.*ts; zeros(m) ] ) )[1:M]
	Y[:,i] = Y[:,i]./( abs.(Y[:,i]) )

	vs = vs + exp.(-im.*ϕ.*txrx_distance[i]).*Y[:,i]'
end

# We want the magnitude of vs
vs = abs.(vs)

# normalize in both directions 
vs_norm = vs./(ones(size(vs) ).*mapslices(maximum, vs, 2) )
vs_norm = vs_norm./(ones(size(vs) ).*mapslices(maximum, vs, 1))





##### -------------------------------------------------------------------- #####
# Extract the normal and higher modes

ind_absmax = findn( vs .== maximum(vs) )
vrpeak = vrt[ind_absmax[1]]
fpeak = f[ind_absmax[2]]

#=

!! This doesn't necessarily work for a glacier since velocity may decrease with depth

# Divide the phase velocity spectra to values corresponding to f > fpeak and f < fpeak
# For f < fpeak the maxima of As must be higher than vrpeak
pvs_lt = vs[vrt .> vrpeak , f .< fpeak ]
f_lt = f[ f .< fpeak ]
vrt_lt = vrt[ vrt .> vrpeak ]

# For f > fpeak the maxima of As must be lower than vrpeak 
pvs_gt = vs[vrt .< vrpeak, f .> fpeak ]
f_gt = f[ f .> fpeak ]
vrt_gt = vrt[ vrt .< vrpeak ]

nlt = size(pvs_lt, 2) 
ngt = size(pvs_gt, 2)

vmaxima = zeros( size(f) )
vmaxima[ ind_absmax[2] ] = vrpeak

!! Not finished 

=#
vmaxima = zeros( size(f) )

lowerlimit_search = 800
vrtll = vrt[vrt .> lowerlimit_search]

for i in 1:M
	ind = findn(vs[ vrt .> lowerlimit_search ,i] .== maximum(vs[ vrt .> lowerlimit_search, i] ) )
	vmaxima[i] = vrtll[ ind[1] ]
end

#

##### -------------------------------------------------------------------- #####
# Plot the MASW phase velocity 

writecsv("FrequencyPhaseVelocity_t3s1.csv", [f vmaxima])


R"""
png("t3s1_g0g11.png", width = 8, height = 6, units = "in", res = 200)
library(RColorBrewer) 
colorpalette <- rev(colorRampPalette(brewer.pal(11, "RdYlBu"))(100))
image($f, $vrt, t($vs), col = colorpalette, xlim = c(0, 80), xlab = "Frequency (Hz)", ylab = "Phase Velocity (m/s)" )
points($f, $vmaxima)
dev.off()

"""
