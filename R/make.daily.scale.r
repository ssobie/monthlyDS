################################################################
##make.daily.scale.r

################################################################

#---------------------------------------------------------------
#' Daily Target Scale Function
#'
#' Iterates over the yearly anomaly files and bias-corrects them
#' to the target resolution.
#' @param var.name Variable name for the netcdf file.
#' @param interp.file Interpolated anomaly file.
#' @param interp.dir Location for the interpolated files.
#' @param target.file Target climatology file.
#' @param target.dir Location for the target climatology file.
#' @param downscale.dir Location for the downscaled file.
#' @keywords downscale
#' @import ncdf4
#' @export

daily_target_scale <- function(var.name,
                               interp.file,interp.dir,
                               target.file,target.dir,
                               downscale.dir) {

  ##Target Climatologies
  tnc <- nc_open(paste0(target.dir,target.file))
  target.clim <- ncvar_get(tnc,var.name)
  nc_close(tnc)

  adjusted.file <- gsub(pattern='interpolated_anomaly_',replacement='downscaled_daily_',interp.file)
  file.copy(from=paste0(interp.dir,interp.file),
            to=paste0(downscale.dir,adjusted.file),overwrite=T)    

  inc <- nc_open(paste0(interp.dir,interp.file))
  anc <- nc_open(paste0(downscale.dir,adjusted.file),write=TRUE)  
  var.dates <- pcict_time(inc)  
  monthly.fac <- as.factor(format(var.dates,'%m'))

  data.atts <- ncatt_get(anc,var.name)
  nlon <- inc$dim$lon$len
  nlat <- inc$dim$lat$len
  ntime <- inc$dim$time$len

  ##Split into loop to handle memory issues effectively
  for (j in 1:nlat) {
    var.data <- ncvar_get(inc,var.name,start=c(1,j,1),count=c(-1,1,-1))
    var.adjust <- var.data*0  
    fac.sub <- monthly.fac
    for(mn in 1:12) {
      var.ix <- which(fac.sub==sprintf('%02d',mn))
      mlen <- length(var.ix)
      target.mean <- t(sapply(target.clim[,j,mn],rep,mlen)) 
      if (var.name=='pr') {
        var.adjust[,var.ix] <- var.data[,var.ix]*target.mean
      }
      if (grepl('tas',var.name)) {
        var.adjust[,var.ix] <- var.data[,var.ix] + target.mean
      }
    }##Loop over Months
    rm(var.data)
    ncvar_put(anc,varid=var.name,vals=var.adjust,start=c(1,j,1),count=c(nlon,1,ntime))
    rm(var.adjust)
  }
  nc_close(inc)
  nc_close(anc)
  gc()
}

