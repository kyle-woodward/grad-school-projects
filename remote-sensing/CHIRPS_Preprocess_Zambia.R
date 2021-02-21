## CHIRPS Precipitation PreProcessing and Time Series Visualization ######################
## Zambia
## Kyle Woodward

library(raster)
library(rgdal)
library(sf)


#download CHIRPS dekadal .tif files from their ftp site---------------------------------

baseurl <- "ftp://chg-ftpout.geog.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/africa_monthly/tifs/chirps-v2.0."

years <- c("2012.", "2013.", "2014.")

months2012 <- c("10", "11", "12")

months2013 <- c("10", "11", "12", 
                  "01", "02", "03",
                  "04", "05")

months2014 <- c("01", "02", "03",
                  "04", "05")

ft <- ".tif.gz"


setwd("S:/USAIDLandesa/DATA/CHIRPS/raw/zipped2012-2013")

#download 2012 dekads
for (month in months2012) {
  file_name <- paste0("2012.", month, ft)
  download.file(url = paste0(baseurl,file_name),
                destfile = file_name, method = "curl", mode = "wb")
}

#download 2013 dekads Jan - May
for (month in months2013[4:8]) {
  file_name <- paste0("2013.", month, ft)
  download.file(url = paste0(baseurl,file_name),
                destfile = file_name, method = "curl", mode = "wb")
}


setwd("S:/USAIDLandesa/DATA/CHIRPS/raw/zipped2013-2014")
#download 2013 dekads Oct - Dec
for (month in months2013[1:3]) {
  file_name <- paste0("2013.", month, ft)
  download.file(url = paste0(baseurl,file_name),
                destfile = file_name, method = "curl", mode = "wb")
}

#download 2014 dekads Jan - May
for (month in months2014) {
  file_name <- paste0("2014.", month, ft)
  download.file(url = paste0(baseurl,file_name),
                destfile = file_name, method = "curl", mode = "wb")
}  

#bring in monthly files and stack them-----------------------------------
setwd("S:/USAIDLandesa/DATA/CHIRPS/raw")

p12_13 <- "unzipped_2012_2013"
p13_14 <- "unzipped_2013_2014"

list_12_13 <- list.files(p12_13,
                        full.names = TRUE,
                        recursive = TRUE)
list_13_14 <- list.files(p13_14,
                        full.names = TRUE,
                        recursive = TRUE)

st12_13 <- stack(list_12_13)
st13_14 <- stack(list_13_14)

#load AOI shapefile
AOI <- st_read("S:/USAIDLandesa/DATA/shp/zmb_adm_2020_shp/zmb_admbnda_adm0_2020.shp") 

#crop and mask to Zambia boundary
crop2012_13 <- crop(st12_13, AOI) %>% mask(AOI)
crop2013_14 <- crop(st13_14, AOI) %>% mask(AOI)

names(crop2012_13) <- names(crop2013_14) <- c("October", "November", "December", 
                                              "January", "February", "March",
                                              "April", "May")

plot(crop2012_13); plot(crop2013_14) #output plots for figures

#output stacks
writeRaster(crop2012_13, "S:/USAIDLandesa/DATA/CHIRPS/processed/Zambia/stack/growseason_monthly2012_13.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)
writeRaster(crop2013_14, "S:/USAIDLandesa/DATA/CHIRPS/processed/Zambia/stack/growseason_monthly2013_14.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)


#create avg growing season precip raster layer 
avg2012_13 <- calc(crop2012_13, fun = mean, na.rm = T)
avg2013_14 <- calc(crop2013_14, fun = mean, na.rm = T)

#plot for figures
plot(avg2012_13, main = "2012 - 2013 mean growing season precipiation \n October - May ")
plot(avg2013_14, main = "2013 - 2014 mean growing season precipiation \n October - May ")

#average the two growing season rasters together
st_allyears <- stack(avg2012_13, avg2013_14)
avg_allyears <- calc(st_allyears, fun = mean, na.rm = T)
plot(avg_allyears, main = "2012 - 2014 mean of growing seasons precipiation \n season = October - May ")

#output
writeRaster(avg2012_13, "S:/USAIDLandesa/DATA/CHIRPS/processed/Zambia/products/precip_meanseason_Oct2012_May2013.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)
writeRaster(avg2013_14, "S:/USAIDLandesa/DATA/CHIRPS/processed/Zambia/products/precip_meanseason_Oct2013_May2014.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)
writeRaster(avg_allyears, "S:/USAIDLandesa/DATA/CHIRPS/processed/Zambia/products/precip_mean_both_season.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)


