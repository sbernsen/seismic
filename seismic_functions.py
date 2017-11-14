#!/home/bernsen/anaconda/python

## User defined functions for seismic processing


def plt_geophone_transect(dt, Y, axs, apk):
	"""	Plot multiple vertical geophone traces nicely. Each trace should 
		correspond to the same time interval. In obspy, this can be 
		called with <object>.plot(type = 'section') but when distance or
		ev_coord isn't specified or when we need better control of the 
		figure then we need to use a custom function. Don't forget to 
		add plt.show() to the script.
		
		Input arguments:
			dt - the sampling time interval 
			Y - an object that contains each traces
			axs - the figure axes need to be passed into the function
			apk - a flag to auto pick the initial onset of seismic energy
	"""

	# import libraries
	import matplotlib.pyplot as plt
	import numpy as np 
	
	n = len(Y) 
	M = len(Y[1].data) 
	
	# preallocate
	
	# define a time variable
	t = np.linspace(0, dt*M, M)
	
	
	# Give the values for adding text to the plot
	str1 = 'G'
	str_spc = '   '
	str2 = 'O-Marker: '
	x = 0.80*M*dt
	
	if apk == 1:
		onsettimes = np.zeros(n)
	
	for indx in range(n):
		y = 0.60*np.max(Y[indx].data)
		axs[indx].plot( t, Y[indx].data, color = 'k')
		
		
		indice = 'No Onset Defined' # This will change if we specify picking
		
		## For the onset of the seismic energy we'll use a z detection picker
		if apk == 1:
			nsta = 2^3 #int(0.01*M)
			nlta =  2**7 #int(0.1*M)
			threshold = 0.6
			indice = onset_zdetect(Y[indx].data, nsta, nlta, 0.5)
			onsettimes[indx] = t[indice]
			## Add the onset pick with a vertical line
			ymin, ymax = axs[indx].get_ylim()
			axs[indx].vlines(t[indice], ymin, ymax, color = 'r')
			
			## Add the end of the coda
			#axs[indx].vlines(t[on_off[1]], ymin, ymax, color = 'b')
		
		
		## label the graph with the geophone number and other information
		strlabel = str1 + str(indx+1) + str_spc + str2 + str(indice)
		axs[indx].text(x, y, strlabel )
	
	## We need to return the values for the onset time 
	if apk == 1:
		return(onsettimes)


def onset_zdetect(ts, nsta, nlta, thresh):
	import numpy as np
	from obspy.signal.trigger import z_detect, recursive_sta_lta, trigger_onset
	
	""" 
	We'll choose the first trigger because we want the onset of the 
	seismic waves.
	"""
	cft = z_detect(ts, nsta)
	
	on_off = trigger_onset(cft, 1, 0.2)
	
	return(on_off[0,0])

def onset_stalta(ts, nsta, nlta, thresh):
	import numpy as np
	from obspy.signal.trigger import recursive_sta_lta, trigger_onset
	
	cft = recursive_sta_lta(ts, nsta, nlta)
	
	
	on_off = trigger_onset(cft, 0.5, 0.2)
	
	return(on_off)


## Function to analyze the time frequency content

## Function to 

##



