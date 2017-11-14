#!/home/bernsen/anaconda/bin/python

# Convert seg2 format to sac using obspy. The file input and output 
# names are input in the script call. The purpose of this code is to edit 
# seg2 data because the 





################################################################################
## Sort out all of the input options and assign default values for those not 
## specified

## Use optparse to provide the option calls for 
## -f, --file=inputfile
## -o, --output=output filename (do not include the .SAC extension)
## -s, --shot=shot location id
## -i, --interval=geophone interval spacing (assuming constant)
## -O, --pick_onset=optional flag to add recursive STA/LTA picker saved as O marker
## -c, --config=optional flag to import metadata values. see README for details 
## -L, --line=transect id value 
## -h 



from optparse import OptionParser

parser = OptionParser()
parser.add_option("-f", "--file", dest="input",
					help="write report to FILE", metavar="FILE")

parser.add_option("-o", "--output", dest="output",
					help="write report to FILE", metavar="FILE")

parser.add_option("-s", "--shot_id", dest="shot",
					help="write report to FILE", metavar="FILE")
					
parser.add_option("-O", "--pick_onset", dest="onset",
					help="write report to FILE", metavar="FILE")

parser.add_option("-c", "--config", dest="config",
					help="write report to FILE", metavar="FILE")
					
parser.add_option("-L", "--line", dest="line",
					help="write report to FILE", metavar="FILE")
					
(options, args) = parser.parse_args() 


## Give a default value for the shot ID if it isn't given
if hasattr(options, 'shot') and options.shot != None:
	shotid = options.shot
else:
	shotid='Unknown Shot Location'

title='Shot Location: ' + shotid + ', Line ID: ' + options.line


## Check if an output filename has been specified
if hasattr(options, 'output') and options.output != None:
	fn = options.output
	fn = fn + '.'
else:
	fn = options.input
	fn = fn[0:(len(fn)-3)]


## Check if we want to auto pick the onset of seismic energy; first break
if hasattr(options, 'onset') and options.onset != None:
	apk = int(options.onset)
else:
	apk = 0 # we don't want to pick 

################################################################################



## Read the input filename and save it as a 
from obspy import read
import numpy as np 
import seismic_functions as sf
import matplotlib.pyplot as plt

#
#filename = 'T1.10GA.S1.dat'
#d = read(filename)
d = read(options.input)

# remove traces that have nan values because no geophone was connected 

L=~np.isnan(d.max())
d = [i for indx, i in enumerate(d) if L[indx] == True]




# setup the figure and define axes objects
n = len(d) 
f, axs = plt.subplots(n, 1, figsize = (12,12))
plt.suptitle(title)

dt = d[0].stats.delta 

if apk == 1:
	onsettimes = sf.plt_geophone_transect(dt, d, axs, apk)	
	print(onsettimes)
else:
	sf.plt_geophone_transect(dt, d, axs, apk)

	
## We will call the plot. During this time, the headerconf.py file can be
## altered to add/edit the sac header variables
plt.show(block=True)


############################## Write the SAC file ##############################
## We want to write in as many header fields as we can
## Some fields may be empty and we may want to edit them later. In order to edit
## sac header variables we must write the sac file then reopen it

if hasattr(options, 'config') and options.config != None:
	config = int(options.config)

if config==1:
	import headerconf as hc
	if hc.geophone_locations:
		gx = hc.geophone_x
		gy = hc.geophone_y
		gz = hc.geophone_z
	if hc.source_location and hc.source_id:
		shotxyz=hc.source_dictionary[shotid]
	elif hc.source_location:
		shotxyz=hc.sourcexyz



## Write the SAC file but number them according to the geophone number 
## of that string. 
import obspy.io.sac.sactrace as sac

print(onsettimes)

for indx in range(n):
	ext=str(indx).zfill(2) 
	ofn = fn + ext + '.SAC'
	d[indx].write(ofn, format='SAC')
	sacdata = sac.SACTrace.read(ofn)
	
	if apk == 1: 
		sacdata.o = onsettimes[indx]
	
	if hc.geophone_locations:
		sacdata.stlo = gx[indx]
		sacdata.stla = gy[indx]
		sacdata.stdp = gz[indx]
	
	if hc.source_location:
		sacdata.evlo = shotxyz[0]
		sacdata.evla = shotxyz[1]
		sacdata.evdp = shotxyz[2]
	
	sacdata.write(ofn)



