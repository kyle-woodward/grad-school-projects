## Data Stack Pre-processing 
## Kyle Woodward

##Update 1/13/2020 - added MI of SAVI for all 3 years, all 3 window sizes, plus ndvi and savi change for 94 to 04
##Update 12/6/2019 - added the 3 MI04 NDVI layers to landsat folder, change reflected in 4 "final" output stacks at bottom 
##Update 11/7/2019 - added categorical predictor rasters, will replace binary rasters in a new stack.
##UPDATE 10/28/2019 - added FID raster derived from polygon dataset ##
##UPDATE 10/23/19 - added combined grapple/edible binary predictor raster ##

##bring in covariate rasters and resample all to 100m res, stack them and output to disk

library(dplyr)
library(sf)
library(raster)
library(rgdal)

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

#Load FID raster
#fid <- raster("C:/Thesis/Data/Processed/FID/fid.tif")

#100m preprocessing ---------- 
#up sample all rasters to 100m res using worldpop stack as extent template, nearest neighbor interpolation
pb100m <- resample(pb_st, wp_st, method = "ngb", progress = "text") 
pc100m <- resample(pc_st, wp_st, method = "ngb", progress = "text")
pi100m <- resample(pi_st, wp_st, method = "ngb", progress = "text")
l100m <- resample(l_st, wp_st, method = "ngb", progress = "text")
cntr100m <- resample(cntr, wp_st, method = "ngb", progress = "text")
#fid100m <- resample(fid, wp_st, method = "ngb", progress = "text")


#make the full stacks
st_bi <- stack(pb100m, l100m, wp_st, cntr100m) 
#st_cat <- stack(pc100m, l100m, wp_st, cntr100m)
st_regression <- stack(pi100m, l100m, wp_st, cntr100m)
st_classification <- stack(pb100m, pc100m, l100m, wp_st, cntr100m)
names(st_bi)
#names(st_cat)
names(st_regression)
names(st_classification)

#old stacks didn't use in final analysis
# writeRaster(st, "C:/Thesis/Data/Processed/stack/st_20191015.tif", #original was binary predictors, l100m, wp_st, cntr100m
#             format = "GTiff",
#             overwrite = TRUE,
#             NAflag = -9999)
# writeRaster(st, "C:/Thesis/Data/Processed/stack/st_20191023.tif", #added grappedible_bi
#             format = "GTiff",
#             overwrite = TRUE,
#             NAflag = -9999)
# writeRaster(st, "C:/Thesis/Data/Processed/stack/st_20191028.tif", #added FID raster
#             format = "GTiff",
#             overwrite = TRUE,
#             NAflag = -9999)

# writeRaster(st_cat, "C:/Thesis/Data/Processed/stack/st_20191107.tif", #categorical predictors, l100m, cntr100m, wp_st, fid100m
#             format = "GTiff",
#             overwrite = TRUE,
#             NAflag = -9999)

## output stacks as of 12/6/19 (still more old stacks) --------------------------
# writeRaster(st_regression, "C:/Thesis/Data/Processed/stack/st_regression.tif", #stack for RF regression using continuous predictors
#             format = "GTiff",
#             overwrite = TRUE,
#             NAflag = -9999)
# 
# writeRaster(st_bi, "C:/Thesis/Data/Processed/stack/st_binary.tif", #stack for RF classification using binary predictors
#             format = "GTiff",
#             overwrite = TRUE,
#             NAflag = -9999)
# 
# writeRaster(st_cat, "C:/Thesis/Data/Processed/stack/st_cat.tif", #stack for RF classification using categorical predictors
#             format = "GTiff",
#             overwrite = TRUE,
#             NAflag = -9999)
# 
# writeRaster(st_classification, "C:/Thesis/Data/Processed/stack/st_classification.tif", #stack for RF classification using bi and cat predictors
#             format = "GTiff",
#             overwrite = TRUE,
#             NAflag = -9999)

#final 100m stacks as of 1/13/20 -----------------------------
writeRaster(st_regression, "C:/Thesis/Data/Processed/stack/st_regression_v2.tif", #stack for RF regression using continuous predictors
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)
writeRaster(st_bi, "C:/Thesis/Data/Processed/stack/st_binary_v2.tif", #stack for RF classification using binary predictors
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)
writeRaster(st_classification, "C:/Thesis/Data/Processed/stack/st_classification_v2.tif", #stack for RF classification using bi and cat predictors
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)

#30m preprocessing (after thesis defense) -------------------
#same method - resample other stacks using WorldPop stack as extent template 

l_30m <- resample(l_st, wp_st, method = "ngb", progress = "text")
pc_st_30m <- resample(pc_st, wp_st, method = "ngb", progress = "text")
pb_st_30m <- resample(pb_st, wp_st, method = "ngb", progress = "text")
cntr_30m <- resample(cntr, wp_st, method = "ngb", progress = "text")

st_cat30m <- stack(pb_st_30m, pc_st_30m, l_30m, wp_st, cntr_30m)

#final 30m stack as of 4/25/2020 ----------------
writeRaster(st_cat30m, "C:/Thesis/Data/Processed/stack/st_classification_30m.tif", #stack for RF classification using bi and cat predictors
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)