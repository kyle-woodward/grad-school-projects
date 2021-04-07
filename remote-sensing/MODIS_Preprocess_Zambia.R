##Download and Preprocess eMODIS East Africa 250m NDVI
## Kyle Woodward
library(tidyr)
library(dplyr)
library(sf)
library(raster)
library(rgdal)

#Download eMODIS 250m monthly product-------------------------------------------------------

baseurl <- "https://edcintl.cr.usgs.gov/downloads/sciweb1/shared/fews/web/africa/southern/dekadal/emodis/ndvi_c6/temporallysmoothedndvi/downloads/monthly//"

months12_13 <- c("1210","1211","1212","1301","1302","1303","1304","1305")
months13_14 <- c("1310", "1311", "1312", "1401", "1402", "1403", "1404", "1405")

#download for 2012-2013
setwd("S:/USAIDLandesa/DATA/MODIS/raw/zipped_Zambia/m2012_2013")
for (month in months12_13) {
  file_name <- paste0("south", month, ".zip")
  download.file(url = paste0(baseurl,file_name),
                destfile = file_name, method = "curl", mode = "wb")
}

#download for 2013-2014
setwd("S:/USAIDLandesa/DATA/MODIS/raw/zipped_Zambia/m2013_2014")
for (month in months13_14) {
  file_name <- paste0("south", month, ".zip")
  download.file(url = paste0(baseurl,file_name),
                destfile = file_name, method = "curl", mode = "wb")
}

#bring in unzipped files 
p1213 <- "S:/USAIDLandesa/DATA/MODIS/raw/unzipped_Zambia/m2012_2013"
p1314 <- "S:/USAIDLandesa/DATA/MODIS/raw/unzipped_Zambia/m2013_2014"


list1213 <- list.files(p1213, full.names = T, recursive = T, pattern = ".tif$")
list1314 <- list.files(p1314, full.names = T, recursive = T, pattern = ".tif$")

st1213 <- stack(list1213) 
st1314 <- stack(list1314)

AOI <- st_read("S:/USAIDLandesa/DATA/shp/zmb_adm_2020_shp/zmb_admbnda_adm0_2020.shp") 

st1213 <- crop(st1213, AOI) %>% mask(AOI)
st1314 <- crop(st1314, AOI) %>% mask(AOI)

#rename stack layers (dekads)
names(st1213) <- names(st1314) <- c("Oct1", "Oct2", "Oct3",
                                      "Nov1", "Nov2", "Nov3",
                                      "Dec1", "Dec2", "Dec3",
                                      "Jan1", "Jan2", "Jan3",
                                      "Feb1", "Feb2", "Feb3",
                                      "Mar1", "Mar2", "Mar3", 
                                      "Apr1", "Apr2", "Apr3",
                                      "May1", "May2", "May3")
#normalize to create NDVI range [-1.0,1.0]
st1213_shrink <- (st1213 - 100)/100
st1314_shrink <- (st1314 - 100)/100

plot(st1213_shrink); plot(st1314_shrink)

#write dekadal NDVI stacks to disk
writeRaster(st1213, "S:/USAIDLandesa/DATA/MODIS/processed/Zambia/stack/ndvi_dekads_2012_2013_stretched.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)
writeRaster(st1314, "S:/USAIDLandesa/DATA/MODIS/processed/Zambia/stack/ndvi_dekads_2013_2014_stretched.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)

writeRaster(st1213_shrink, "S:/USAIDLandesa/DATA/MODIS/processed/Zambia/stack/ndvi_dekads_2012_2013.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)
writeRaster(st1314_shrink, "S:/USAIDLandesa/DATA/MODIS/processed/Zambia/stack/ndvi_dekads_2013_2014.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)

#calculate mean NDVI per yearly stack
mean2012_2013 <- calc(st1213_shrink, fun = mean, na.rm = T)
mean2013_2014 <- calc(st1314_shrink, fun = mean, na.rm = T)

st_allyears <- stack(mean2012_2013, mean2013_2014)
mean_allyears <- calc(st_allyears, fun = mean, na.rm = T)

#plot for figures
plot(mean2012_2013, main = "Mean Growing Season NDVI \n October 2012 - May 2013") 
plot(mean2013_2014, main = "Mean Growing Season NDVI\n October 2013 - May 2014")
plot(mean_allyears, main = "Mean of 2012-2013 and 2013-2014 Growing Seasons \n Growing Season = October - May")

#write mean NDVI tifs to disk
writeRaster(mean2012_2013, "S:/USAIDLandesa/DATA/MODIS/processed/Zambia/products/ndvi_mean_season2012_2013.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)
writeRaster(mean2013_2014, "S:/USAIDLandesa/DATA/MODIS/processed/Zambia/products/ndvi_mean_season2013_2014.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)
writeRaster(mean_allyears, "S:/USAIDLandesa/DATA/MODIS/processed/Zambia/products/ndvi_mean_both_seasons.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)