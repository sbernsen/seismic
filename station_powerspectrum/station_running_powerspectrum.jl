## Download 3 hr data windows with one hour overlap without saving the data
## files then compute the median periodogram with confidence intervals for
## that interval for a set length window. The spectral statistic is centered
## at the middle of the time interval of the time series. Dataless files need
## to be downloaded prior to running this code.
##
## 
## The input delimited text file 'station_parameters.txt' provides 
## network, station, location, channel, start time, end time, time interval,
## metadata filename, fft window length, and the output filename (without extension)
##
## ------------------------------------------------------------------------- ##

# Load modules
using SAC, seismicTSA 

# read the text file 'station_parameters.txt'
T = readdlm("station_parameters.txt", ',' )

network = strip( (T[ T[:,1] .== "network",2])[1]  )
station = strip( (T[ T[:,1] .== "station", 2] )[1] )
location = strip( (T[ T[:,1] .== "location", 2] )[1] )
channel = strip( (T[ T[:,1] .== "channel", 2])[1] )
start_time = DateTime( strip( (T[ T[:,1] .== "start_time", 2])[1] ) )
end_time = DateTime( strip( (T[ T[:,1] .== "end_time", 2])[1] ) )
time_interval =  (T[ T[:,1] .== "time_interval", 2])[1]
metadata = strip( (T[ T[:,1] .== "metadata", 2])[1] )
fft_window = (T[ T[:,1] .== "fft_window", 2] )[1]


s0 = "."
s1 = join( split( split(string(start_time), "T")[1], "-"), s0)
s2 = join( split( split(string(end_time), "T")[1], "-"), s0)
s3 = network*s0*station*s0*location*s0*channel
output_filename = s1*s0*s2*s0*s3*s0

# Define some psd paramaters
overlap = Int( floor(fft_window/2 ) )
ACF = false 

## Let's get the sampling interval in terms of hours plus minutes. Seconds will
## be truncated


## We need to make the IRIS query file in the form 
##	http://service.iris.edu/fdsnws/dataselect/1/query?net=AK&sta=BCP&start=...
#
# The power spectrum will centered on 2 hour intervals (i.e. median over 2 hours ) 
date_start = start_time:Dates.Hour(1):( end_time - Dates.Hour(2) )
date_center = start_time + Dates.Hour(1):Dates.Hour(1):( end_time - Dates.Hour(1) )
date_final = start_time + Dates.Hour(2):Dates.Hour(1):end_time

amp="&"
url_prefix = "http://service.iris.edu/fdsnws/dataselect/1/query?"

# Let's download the data and process it
N = length(date_start) 

# Allocate space
time_spectrum_median = zeros(fft_window + 1, N)
time_spectrum_stdev = zeros(fft_window + 1, N) 
freqs = [] 
ts = []

for i in 1:N


	query ="net="*network*amp*"sta="*station*amp*"loc="*location*amp*"cha="*channel*amp*"starttime="*string(date_start[i])*amp*"endtime="*string(date_final[i])

	data_url = url_prefix*query

	# download the data
	run(`curl -L -o data_download.mseed $data_url`)
	
	# the data comes as miniSEED format so let's put it into SAC
	run(`mseed2sac data_download.mseed`)

	# remove the mseed file 
	run(`rm data_download.mseed`)

	# Sometimes there are data gaps which means that no data has been downloaded. 
	# If so, catch it so that the code doesn't return an error

	sac_file = (filter(x->contains(x,".SAC"), readdir(".")) )

	try sac_file[1]
	catch
		println("No data was downloaded")
		continue
	end



	
	# remove the instrument response from the time series via SAC since it is 
	# the easiest and possibly the fastest way. There is a bash script to do
	# so. 
	run(`bash remove_instrument.bsh`)

	# read in the sac file so we can compute the spectrum 
	ts = SAC.read(sac_file[1])

	# In case we download a small snippet less than the window we want then we need to forget about it and move on in life
	if length(ts.t) < fft_window
		println("Downloaded data was not sufficient")
		run(`rm -f $sac_file`)
		continue
	end

	fs = 1/ts.delta
	freqs, time_spectrum_median[:,i], time_spectrum_stdev[:,i] = psdpdf(ts.t, fft_window, overlap, fs, ACF)
	run(`rm -f $sac_file`)

end


tv = collect(date_center)
# The output file 
writecsv( output_filename*"median.csv", time_spectrum_median)
writecsv( output_filename*"stdev.csv", time_spectrum_stdev )
writedlm( output_filename*"frequency.txt", freqs)  
write( output_filename*"time.txt", tv)
