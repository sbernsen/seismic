# Plotting functions to make life easy
library(caTools)
library(colorRamps)
library(matlab)


pm_polygon_fill <- function(x, y, shift , line_fill) 
{

  pos_x <- c(x, rev(x) )
  pos_y <- ifelse(y >= shift, y, shift) 
  pos_y <- c(pos_y, rep(shift, length(pos_y) ) )
  
  neg_x <- pos_x
  neg_y <- ifelse(y <= shift, y, shift) 
  neg_y <- c(neg_y, rep(shift, length(neg_y) ) )
  

  polygon(pos_y, pos_x, col = line_fill[1], lwd = 0.5)
  polygon(neg_y, neg_x, col = line_fill[2], lwd = 0.5)
  
}

ts_norm <- function(df, k) 
{
  n <- dim(df)[2]
  for( i in 1:n)
  {
    df[,i] <- df[,i]/runsd(df[,i], k, endrule = "sd")
  }
  
  return(df)
}

ts_yshifts <- function( df, shift_factor )
{
  m <- dim(df)[1]
  n <- dim(df)[2]
  
  mns <- apply(abs(df), 2, max, na.rm = T )
  mns <- t(matrix(mns, n, m ) ) 
  df <- df/mns
  
  amp_shift <- seq(1, n)*shift_factor
  
  df <- t( matrix( amp_shift, n, m) ) + df
  
  return( list(amp_shift = amp_shift, ts_shift = df) )
  
}


## -------------------------------------------------------------------------------- ##
plot_geophone_wiggles <- function( time_vec, df, line_fill, vert, main_col)
{
  # You must add your own axis labels  
  df <- ts_yshifts(df, 1) 
  amp_shift <- df$amp_shift
  df <- df$ts_shift 
  par(bg = NA, col.lab = main_col, col.axis = main_col, col.sub = "white", col = main_col)

  da <- diff(amp_shift)[1]
  if( vert )
  {
    plot( df[,1], time_vec, type = "l", xlim = c(min(amp_shift)-da, max(amp_shift)+da ),
         ylim = c(max(time_vec), min(time_vec) ), xlab = "Geophone Number", ylab = "Travel Time (s)", 
         lwd = 1.5, xaxs = "i" )

    if(line_fill[1] != "none" )
    {
      pm_polygon_fill(time_vec, df[,1], amp_shift[1], line_fill)
      for(i in 2:length(amp_shift) )
      {
        lines( df[,i], time_vec, lwd = 1.5)
        pm_polygon_fill(time_vec, df[,i], amp_shift[i], line_fill)
      }
    }else 
    { 
      for(i in 2:length(amp_shift) )
      {
        lines( df[,i], time_vec, lwd = 1.5)
      }
    }
  }else
  {
    plot( time_vec, df[,1], type = "l", ylim = c(min(amp_shift), max(amp_shift) ),
         xlim = c(min(time_vec), max(time_vec) ), yaxt = "n" , xlab = "", ylab = "",
         lwd = 1.5, xaxs = "i")
  
    if(line_fill[1] != "none" )
    {
      pm_polygon_fill(time_vec, df[,1], amp_shift[1], line_fill)
      for(i in 2:length(amp_shift) )
      {
        lines( time_vec, df[,i], lwd = 1.5)
        pm_polygon_fill(time_vec, df[,i], amp_shift[i], line_fill)
      }
    }else 
    {  
      for(i in 2:length(amp_shift) )
      {
        lines( time_vec, df[,i], lwd = 1.5)
      }
    
    }
  }

#if( !is.null(direct_wave) && vert )
#  {
#    lines( amp_shift, direct_wave, col = "green4", lwd = 1.5)
#  }else if( !is.null(direct_wave) )
#  {
#    lines( direct_wave, amp_shift, col = "green4", lwd = 1.5) 
#  }
  return(amp_shift)
}



plot_stransform <- function(ts, stran, f, tv)
# This is a quick and dirty plot for a stacked subplot of the time series being analyzed and the S-transform 
# Input:
#   ts - the m-by-1 amplitude vector
#   tv - the m-by-1 time vector as seconds
#   f - frequency as hertz
# 
#
{

  layout( matrix( c(1, 1, 2, 2, 2, 2), nrow = 3, ncol = 2, byrow = TRUE) )

  plot( tv, ts, type = "l", xlab = "Time (s)", xaxs = "i")

  imagesc(tv, f, abs(stran), col = matlab.like(50), ylab = "Frequency (Hz)", xlab = "Time (s)" )

}

plot_cwt <- function(ts, cwt, period, time_vec) 
{
  layout( matrix( c(1, 1, 2, 2, 2, 2), nrow = 3, ncol = 2, byrow = TRUE) )
  plot( time_vec, ts, type = "l", xlab = "Time (s)", xaxs = "i")
  image(time_vec, period, abs(cwt), col = matlab.like(50), ylab = "Period (s)", xlab = "Time (s)")

}

plot_radarco <- function(x, z, im)
{
  gs = gray.colors(50) 
  
}



single_pick <- function(tv, ts, f, envelope, time_pick_indice)
{

  key_press <- "0" 
  kp <- 1

  if(envelope)
  { 
    while( key_press == "0")
    {
      library(RSEIS) 
      ts <- envelope(ts)

      if(kp == 1 && is.na(time_pick_indice) )
      {
        ind <- which(ts == max(ts))
        kp <- kp + 1
      }else 
      {
        ind <- time_pick_indice
      }

      plot(tv, ts, type = "l", main = round(f) )
      points(tv[ind], ts[ind], pch = 1)

     
      
      max_save <- readline(prompt = "Is the autopick correct [1/0]\n")

      if(max_save == "1")
      {
        key_press == "1" 
        kp <- 1
        print(kp) 
        print("Maximum autopick taken")
        break
      }

      ind <-  as.numeric(identify(tv, ts, n=1, plot = F) )
      points(tv[ind], ts[ind], pch = 3)
      key_press <- readline(prompt = "Press [0] to redo [1] to save\n")
      print(key_press) 

    }
  }else
  {
    while(key_press == "x")
    {
      plot(tv, ts, type = "l")
      pick_ind <-  as.numeric( identify(tv, ts, n = 1) )
      points( tv[ pick_ind ], ts[pick_ind] , pch = 3 )
      key_press <- readline(prompt = "Press [x] to redo [s] to save")
    
    }
  }

  pick_vals <- c(ind, tv[ind], ts[ind])
  return(pick_vals) 

}


array_pick_quick <- function(X, tv, line_fill, time_id, shift_factor, vertical)
{


  X <- ts_yshifts(X, shift_factor)  
  amp_shift <- X$amp_shift
  X <- X$ts_shift

  # Create a new device 
  par(bg = NA, col = "black", col.lab = "black", col.axis = "black", col.sub = "black")

  plot( tv, X[,1], type = "l", xlim = c( min(tv), max(tv) ), ylim = c(min(X), max(X) ), xlab = "", ylab = "Travel Time (s)",  xaxt = "n", 
         lwd = 1.5, xaxs = "i" )

  pm_polygon_fill(tv, X[,1], amp_shift[1], line_fill)
  for(i in 2:length(amp_shift) )
  {
    lines( tv, X[,i], lwd = 1.5)
    pm_polygon_fill(tv, X[,i], amp_shift[i], line_fill)
  }


  n <- dim(X)[2] 
  x <- X[1,]

  #lines(time_id[,2], x, col = "red", lwd = 3)

  for(i in 1:n) 
  {

    lines(tv, X[,i], col = "black", cex = 1.5)
    print("Pick a point\n")
    ind <-  as.numeric( identify( tv, X[,i], n=1, plot = F) )
    points( tv[ ind ], x[i], pch = "|", cex = 2 )
    #key_press <- readline(prompt = "Press [x] to redo, [n] for next, [q] to quit, [0-9] to save a pick id number\n")
    

    #if(key_press == "n")
    #{
    #  print("Moving on to the next trace.\n\n")
    #  next
    #}

    #if(key_press == "q")
    #{
    #  break
    #}

    #while(key_press == "x" )
    #{
        
    #  ind <-  as.numeric(identify( tv, X[,i], n=1, plot = F))
    #  points( tv[ ind ], X[1,i] , pch = "|", cex = 2 )
    #  key_press <- readline(prompt = "Press [x] to redo [0-9] to save a pick id number\n")

    #}

    time_id[i,] <- c( as.numeric(ind), as.numeric(tv[ind]) ) 

    #plot( tv, X[,1], type = "l", xlim = c(min(tv), max(tv) ),
    #     ylim = c(0, max(X) ), xlab = "", ylab = "Travel Time (s)", xaxt = "n", 
    #     lwd = 1.5, xaxs = "i" )

    #pm_polygon_fill(tv, X[,1], amp_shift[1], line_fill)

    #for(i in 2:length(amp_shift) )
    #{
    #  lines( tv, X[,i], lwd = 1.5)
    #  pm_polygon_fill(tv, X[,i], amp_shift[i], line_fill)
    #}


  }

  return(time_id)

}



array_pick_vertical <- function(X, tv, line_fill, time_id, shift_factor)
{


  X <- ts_yshifts(X, shift_factor)  
  amp_shift <- X$amp_shift
  X <- X$ts_shift

  # Create a new device 
  par(bg = NA, col = "black", col.lab = "black", col.axis = "black", col.sub = "black")

  plot( X[,1], tv, type = "l", ylim = c( max(tv), min(tv) ), xlim = c(min(X), max(X) ), xlab = "", ylab = "Travel Time (s)",  xaxt = "n", 
         lwd = 1.5, xaxs = "i" )

  pm_polygon_fill(tv, X[,1], amp_shift[1], line_fill)
  for(i in 2:length(amp_shift) )
  {
    lines( X[,i], tv, lwd = 1.5)
    pm_polygon_fill(tv, X[,i], amp_shift[i], line_fill)
  }


  n <- dim(X)[2] 
  x <- X[1,]

  lines(x, time_id[,2], col = "red", lwd = 3)

  for(i in 1:n) 
  {

    lines(X[,i], tv, col = "black", cex = 1.5)
    print("Pick a point\n")
    ind <-  as.numeric( identify( X[,i], tv, n=1, plot = F) )
    points( x[i] , tv[ ind ], pch = "-", cex = 2 )
    key_press <- readline(prompt = "Press [x] to redo, [n] for next, [q] to quit, [0-9] to save a pick id number\n")
    
#    if( key_press != "x" || as.numeric(key_press) > 9 )
#    {
#      key_press <- "x"
#    }  
    if(key_press == "n")
    {
      print("Moving on to the next trace.\n\n")
      next
    }

    if(key_press == "q")
    {
      break
    }

    while(key_press == "x" )
    {
        
      ind <-  as.numeric(identify( X[,i], tv, n=1, plot = F))
      points( X[1,i] , tv[ ind ], pch = "-", cex = 2 )
      key_press <- readline(prompt = "Press [x] to redo [0-9] to save a pick id number\n")

    }

    time_id[i,] <- c( as.numeric(ind), as.numeric(tv[ind]), as.numeric(key_press) ) 

    plot( X[,1], tv, type = "l", xlim = c(min(X), max(X) ),
         ylim = c(max(tv), min(tv) ), xlab = "", ylab = "Travel Time (s)", xaxt = "n", 
         lwd = 1.5, xaxs = "i" )

    pm_polygon_fill(tv, X[,1], amp_shift[1], line_fill)
    for(i in 2:length(amp_shift) )
    {
      lines( X[,i], tv, lwd = 1.5)
      pm_polygon_fill(tv, X[,i], amp_shift[i], line_fill)
    }

    lines(x, time_id[,2], col = "red", lwd = 3)

  }

  return(time_id)

}


update_picks <- function(X,tv,line_fill,file_pattern)
# we want to visualize the points that we've already picked so that we don't pick them twice. The files for saved picks are of the form 'file_pattern' which means that any files containing this pattern will be read in.
{

  X <- ts_yshifts(X) 
  amp_shift <- X$amp_shift
  X <- X$ts_shift 
  par(bg = NA, col = "black", col.lab = "black", col.axis = "black", col.sub = "black")

  plot( X[,1], tv, type = "l", ylim = c( max(tv), min(tv) ), xlim = c(min(X), max(X) ), xlab = "", ylab = "Travel Time (s)",  xaxt = "n", 
         lwd = 1.5, xaxs = "i" )

  pm_polygon_fill(tv, X[,1], amp_shift[1], line_fill)
  for(i in 2:length(amp_shift) )
  {
    lines( X[,i], tv, lwd = 2)
    pm_polygon_fill(tv, X[,i], amp_shift[i], line_fill)
  }

  
  fn <- dir(pattern=file_pattern)
  n <- length(fn) 

  airwave_time <- read.csv("picks_airwave.csv") 

  lines(amp_shift, airwave_time$TRAVEL_TIME, col = "red", lwd = 1.5)

  if(n > 0)
  {
    for(i in 1:n )
    {
      ppk <- read.csv(fn[i])
      ppk_twt <- ppk$TRAVEL_TIME[ ppk$INDICE - airwave_time$INDICE > 0 ]
      x <- amp_shift[ppk$INDICE - airwave_time$INDICE > 0]
      lines(x, ppk_twt, col = "red", lwd = 2)
    }
  }
  
}


plot_timespectrum <- function(tv, freqs, time_spectrum, isdate)
# Plot the timeseries of a power spectrum 
# 
# INPUT:
#   tv -              the n-by-1 time vector input as a numeric vector or a 
#                     date vector
#   freqs -           the m-by-1 frequency vector 
#   time_spectrum -   the m-by-n array of spectral values
#   isdate -          boolean value specifying whether the time vector is a 
#                     date object. If so tv needs to be in the format:
#                          yyyy-mm-ddThh:mm:ss
#          
{

 library(colorRamps)


 N <- length(tv) 

 if(isdate) 
 {

  # The following few lines might have to be modified depending on the problem. Usually day formats will be from data downloaded from IRIS so they will come in this format.

  mydhms <- strsplit(tv, "T")
  tv <- t( matrix(unlist(mydhms), 2, N) ) 
  tv <- paste(tv[,1], tv[,2])
  tv <- as.POSIXlt( tv, tz = "GMT", format = "%m-%Y-%d %H:%M:%S")

 }
 
 image(tv, freqs, t(time_spectrum) , col = blue2red(30) )


}


