################################################################
##interpolate.anomalies.r

################################################################

#---------------------------------------------------------------
#' Interpolate Anomalies Function
#'
#' Uses CDO to bilinearly interpolate calculated anomalies to a
#' target resolution. The interpolated files are split into 
#' individual years to reduce their size.
#' @param var.name Variable name for the netcdf file.
#' @param  anomaly.file File name for anomaly netcdf file.
#' @param  read.dir Location for the anomaly file.
#' @param  grid.file File containing target grid information.
#' @param  grid.dir Location for the grid file.
#' @param  write.dir Location for the interpolated files.
#' @keywords interpolate
#' @import ncdf4
#' @export

interpolate_anomalies <- function(var.name,
                                  anomaly.file,read.dir,
                                  grid.file,grid.dir,
                                  write.dir) {

  nc <- nc_open(paste0(read.dir,anomaly.file))
  dates <- pcict_time(nc)
  years <- unique(format(dates,'%Y'))
  
  ##Split the anomaly file into 1-year files
  for (y in years) {

    tmp.file <- paste0('interpolated_',anomaly.file)
    work <- paste('cdo seldate,',y,'-01-01T00:00,',y,'-12-31T23:59 ',read.dir,anomaly.file,' ',write.dir,tmp.file,sep='')
    system(work)
    if (!file.exists(paste0(write.dir,tmp.file)))
      warning('Temp file was not created')

    snc <- nc_open(paste0(write.dir,tmp.file))
    start.time <- ncvar_get(snc,'time')
    interval.bounds <- find_interval_dates(dates,y,y)
    year.dates <- dates[interval.bounds$start:interval.bounds$end]
    nc_close(snc)

    interp.file <- gsub(pattern='[0-9]{4}-[0-9]{4}',replacement=y,tmp.file)
    work <- paste0('cdo -s remapbil,',grid.dir,grid.file,' ',write.dir,tmp.file,' ',write.dir,interp.file)
    system(work)

    file.remove(paste0(write.dir,tmp.file))
  }
  gc()  
}


################################################################################

