

t1 <- as.matrix( read.csv("T1_new.csv", header = F) ) #read.csv("FrequencyPhaseVelocity_t1s1.csv", header = F) )
t2 <- as.matrix( read.csv("T2_new.csv", header = F) ) #read.csv("FrequencyPhaseVelocity_t2s1.csv", header = F) )
t3 <- as.matrix( read.csv("T3_new.csv", header = F) ) #read.csv("FrequencyPhaseVelocity_t3s1.csv", header = F) )


resampler <- function(data) 
{
    n <- nrow(data)
    resample.rows <- sample(1:n,size=N,replace=FALSE)
    return(data[resample.rows,])
}

spline.estimator <- function(data,m) 
{
    fit <- smooth.spline(x=data[,1],y=data[,2], cv=TRUE)
    eval.grid <- seq(from=min(data[,1]),to=max(data[,1]),length.out=m)
    return(predict(fit,x=eval.grid)$y) # We only want the predicted values
}

spline.estimator2 <- function(data,dx) 
{
    fit <- smooth.spline(x=data[,1],y=data[,2], cv=TRUE)
    eval.grid <- seq(from=min(data[,1]), to=max(data[,1]), by=dx)
    return(list( y = predict(fit,x=eval.grid)$y, x=eval.grid) ) # We only want the predicted values
}

spline.cis <- function(data,B,alpha,m, N) 
{
    spline.main <- spline.estimator(data,m)
    fit <- smooth.spline(x=data[,1],y=data[,2], cv=TRUE)
    spline.boots <- replicate(B,spline.estimator(resampler(data),m=m))
    cis.lower <- 2*spline.main - apply(spline.boots,1,quantile,probs=1-alpha/2)
    cis.upper <- 2*spline.main - apply(spline.boots,1,quantile,probs=alpha/2)
    return(list(main.curve=spline.main,lower.ci=cis.lower,upper.ci=cis.upper, dof = fit$df,
    x=seq(from=min(data[,1]),to=max(data[,1]),length.out=m)))
}

alpha <- 0.05
B <- 1000
N <- 40
m <- 2000

#t1.sp <- spline.cis(t1, B, alpha, m, N)
#t2.sp <- spline.cis(t2, B, alpha, m, N)
#t3.sp <- spline.cis(t3, B, alpha, m, N)


xlimits <- c(10, 120)
remove_points <- function(x, y, xlimits)
{
  dev.new()
  plot(x, y, xlim = xlimits)
  rm_pts <- 0
  
  id <- readline(prompt = "Pick points (y/n)\n")
  
  while(id ==  "y") 
  {
  
    plot(x, y, xlim = xlimits) 
    ind <- identify(x,y, n=1)
    x <- x[-ind]
    y <- y[-ind]
    id <- readline(prompt = "Pick another (y/n)\n") 
    
  }  
  
  return( list(x = x, y = y) )
}



t1.p <- remove_points(t1[,1], t1[,2], xlimits)
t2.p <- remove_points(t2[,1], t2[,2], xlimits) 
t3.p <- remove_points(t3[,1], t3[,2], xlimits)


#dev.new()
main_col <- "white"

png("DispersionComparison.png", width = 6, heigh = 6, units = "in", res = 100)
par(bg = NA, mai = c(1, 1, 0.1, 0.1), 
  col.lab = main_col, col.axis = main_col, col.sub = main_col, col = main_col )
plot(t1.p$x, t1.p$y, pch = 0, xlim = c(10, 120), col = "red",
  xlab = "Frequency (Hz)", ylab = "Phase Velocity (m/s)", cex.lab = 1.5, cex.axis = 1.5)
points(t2.p$x, t2.p$y, pch = 3, col = "green4")
points(t3.p$x, t3.p$y, pch = 6, col = "blue4")
legend(100, 3200, c("T1", "T2", "T3"), col = c("red", "green4", "blue4"), pch = c(0, 3, 6), cex=2, bty = "n" )
dev.off()


write.csv(cbind(t1.p$x, t1.p$y), "T1_new.csv", quote = F, row.names = F )
write.csv(cbind(t2.p$x, t2.p$y), "T2_new.csv", quote = F, row.names = F )
write.csv(cbind(t3.p$x, t3.p$y), "T3_new.csv", quote = F, row.names = F )


