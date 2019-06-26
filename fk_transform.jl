#=
F-K transform and plot of an active source survey
=# 

using SAC, DSP, RCall

# Read in the ordered list of filenames for each stations 
station_filenames = readdlm("station_list.txt")
station_filenames = station_filenames[:,1]

# We need Δt and Δx. We can get Δt from the SAC header but for now we'll define Δx 
dx = 10.0

# Let's load the data into an array 
# Read in the first data file to allocate space 
ts = SAC.read(station_filenames[1])
dt = ts.delta
ts = ts.t

m = length(ts) 
n = length(station_filenames) 

M = 3m

fk = complex(  zeros(M, n)  )

# Taper, pad and compute the fft of the time series then assign the first column
wt = tukey(m, 0.1)
fk[:,1] = fftshift(fft( [ zeros(m); wt.*ts; zeros(m) ] ))

for i in 2:n
	ts = SAC.read(station_filenames[i])
	ts = ts.t
	fk[:,i] = fftshift( fft( [ zeros(m); wt.*ts; zeros(m) ] ), 1)
end

#taper and pad in the x domain 
wt = tukey(n+2, 0.1)[2:end-1]
wt = (ones( size(fk) ) ).*wt' 

padding = zeros( size(fk, 1) , Int( 2^( 1 + ceil(log2(n) ) ) ) )

fk = [padding fk.*wt padding ] 

# use the ifft on each row 
fk = ifftshift( ifft(fk, 2), 2 )

# Assign the frequency and wavenumber vectors 
n = size(fk,2)

kxnyq = 1/(2dx)
dkx = 2.*kxnyq/(n-1)
k = collect( [0:dkx:kxnyq-dkx; -kxnyq:dkx:-dkx] )
k = collect( -kxnyq:dkx:kxnyq )


fnyq=1. / (2dt)
df=2*fnyq/(M-1)
f = collect(-fnyq:df:fnyq)

fk = ( abs.(fk) )/(dkx*df)


fticks = collect(0:25:1000)
kticks = collect(-kxnyq:0.01:kxnyq)

R"""

library(RColorBrewer) 
colorpalette <- rev(colorRampPalette(brewer.pal(11, "RdYlBu"))(40))
dev.new(width = 6, height = 10, units = "in")

par(mai = c(1, 1, 1, 0.5), bg = NA )

image($k, $f, t($fk), col = colorpalette, ylab = "Frequency (Hz)", 
	xlab = "", xaxt= "n", yaxt = "n", ylim = c(250, 10), cex.lab = 1.5)
axis(side=2, at=$fticks, labels=$fticks, las=2)
axis(side=3, at=$kticks, labels=$kticks*100)
mtext("Wavenumber (m)", side = 3, cex = 1.5, padj = -2.5)
mtext(expression(paste("10"^"-2" ) ), 3, adj = 1.075 )
grid(nx = 2, ny = 5, col = "black", lty = 2)



"""



#=
#=
Plot the phase dispersion 
=#

max_freq = 80
min_velocity = 200 
max_velocity = 3300

# Calculate the phase velocity matrix for the positive f and k values
fk = fk[ f .> 0, :]
f = f[f .> 0]

fk = fk[ f .<= max_freq, :]
f = f[f .<= max_freq]

#k = k[k .> 0]

m,n = size(fk) 
F = ones( size(fk) ).*f
K = ones(size(fk) ).*k'
pv = F./K 

fvm = [ reshape(F, prod(size(F) ), 1 ) reshape(pv, prod(size(pv) ), 1 ) reshape(fk, prod(size(fk) ), 1 )]
fvm = fvm[fvm[:,2] .<= max_velocity,: ]
fvm = fvm[fvm[:,2] .>= min_velocity,: ]



R"""
library(RColorBrewer) 
colorpalette <- rev(colorRampPalette(brewer.pal(11, "RdYlBu"))(40))
f <- seq(0, $max_freq, by = 0.25)
v <- seq($min_velocity, $max_velocity)
library(akima) 
fvm <- interp( $fvm[,1], $fvm[,2], $fvm[,3], xo = f, yo = v)
fvm$z <- ifelse( is.na(fvm$z), 0, fvm$z)
image(fvm, col = colorpalette, ylim = c($min_velocity, $max_velocity) )
"""

=#


