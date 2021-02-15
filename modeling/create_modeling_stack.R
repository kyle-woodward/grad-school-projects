## Data Stack Pre-processing 
## Kyle Woodward

library(dplyr)
library(sf)
library(raster)
library(rgdal)

##bring in covariate rasters and resample all to 100m res, stack them and output to disk----

#Load Binary Predictor rasters
path1 <- "C:/Thesis/Data/Processed/predictors/binary"
pb <- list.files(path1, full.names = T, pattern = ".tif$")
pb_st <- stack(pb)

#Load Categorical Predictor rasters
path2 <- "C:/Thesis/Data/Processed/predictors/cat"
pc <- list.files(path2, full.names = T, pattern = ".tif$")
pc_st <- stack(pc)

#Load Use Index Predictor rasters
path3 <- "C:/Thesis/Data/Processed/predictors/regression"
pi <- list.files(path3, full.names = T, pattern = ".tif$")
pi_st <- stack(pi)

#Load Landsat covariate rasters
path4 <- "C:/Thesis/Data/Processed/landsat"
l <- list.files(path4, full.names = T)
l_st <- stack(l)

#Load WorldPop covariate rasters (specify 30m or 100m set of tifs using pattern argument)
path5 <- "C:/Thesis/Data/Processed/worldpop"
wp <- list.files(path5, full.names = T, pattern = "..30m.tif$")
wp_st <- stack(wp)

#Load countries covariate raster
cntr <- raster("C:/Thesis/Data/Processed/countries/countries.tif")

#100m preprocessing ---------- 
#up sample all rasters to 100m res using worldpop stack as extent template, nearest neighbor interpolation
pb100m <- resample(pb_st, wp_st, method = "ngb", progress = "text") 
pc100m <- resample(pc_st, wp_st, method = "ngb", progress = "text")
pi100m <- resample(pi_st, wp_st, method = "ngb", progress = "text")
l100m <- resample(l_st, wp_st, method = "ngb", progress = "text")
cntr100m <- resample(cntr, wp_st, method = "ngb", progress = "text")

#make the full stacks
st_classification <- stack(pb100m, pc100m, l100m, wp_st, cntr100m)
#print names of raster layers in stack to input into RF model script
names(st_classification)

#Export 100m stack 
writeRaster(st_classification, "C:/Thesis/Data/Processed/stack/st_classification_v2.tif", #stack for RF classification using bi and cat predictors
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)