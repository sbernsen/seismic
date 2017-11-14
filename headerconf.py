## Set specific variables to be included in the SAC header
##
##!!!! Set the boolean to TRUE if you want to import specific fields
import numpy as np


## List of Booleans
geophone_locations = True
source_location = True
source_id = True # Create a dictionary for the sources if this is true

########## ------------------- geophone_locations ------------------- ##########


## List the x,y locations of each geophone in meters
geophone_x = np.array([10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10 ]) + 310


### ------------------------------------------------------ ###
###!!! 		Transverse Lines T1, T2, T3		!!!###

#geophone_x = np.array([0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110])
#geophone_x = np.array([130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240])
#geophone_x = np.array([230, 240, 250, 260, 270, 280, 290, 300, 310, 320, 330, 340])

### ------------------------------------------------------ ###



#geophone_y = np.array([0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110 ]) 
geophone_y = np.array([110, 100, 90, 80, 70, 60, 50, 40, 30, 20, 10, 0 ]) 
#geophone_y = np.array([60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60 ])


geophone_z = np.array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

########## --------------------- source_location -------------------- ##########
## Enter the source locations in meters

sourcexyz=None

source_dictionary = {'S1': np.array([120, 60,2]),
'S2': np.array([230,110,2]),
'S3': np.array([230,60,2]),
'S4': np.array([230,10,2]),
'S5': np.array([290,0,2]) }


########## ----------------------------  ---------------------------- ##########

########## ----------------------------  ---------------------------- ##########

########## ----------------------------  ---------------------------- ##########

########## ----------------------------  ---------------------------- ##########
