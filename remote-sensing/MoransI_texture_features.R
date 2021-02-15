## Create MoransI texture features from Landsat NDVI and SAVI 
## Kyle Woodward
library(dplyr)
library(sf)
library(raster)
library(rgdal)

#Create reproducible small rasters for testing --------------------------------

#create two empty rasters, fill one with ordered values 1-2500 (50x50)
r <- r1 <- raster(nrows = 50, ncols = 50)
values(r) <- 1:ncell(r)
plot(r)
#fill the other raster with randomly distributed values from 0-1 - we'll use this one to test some things out
set.seed(20)
values(r1) <- runif(ncell(r)) #runif creates random deviated values about the mean of the values in r
hasValues(r1)
values(r1)[1:ncell(r)]
plot(r1)

#Creating Rooks and Queens Case Contiguity Focal Neighborhoods----------------

# Rooks case neighborhoods 
# (ended up not using rooks case for Moran's I, but you can run these to see the difference from queens case)
f3_r <- matrix(c(0,1,0,1,0,1,0,1,0), nrow = 3) #custom rooks case neighborhood
f5_r <- matrix(c(0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0), nrow = 5)
f7_r <- matrix(c(0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0), nrow = 7)

# Queens case neighborhoods 
# (default for MoranLocal is to use Queen's case and a 3x3 neighborhood, so we don't need to create the 3x3)
f5_q <- matrix(c(1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1), nrow = 5)
f7_q <- matrix(c(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1), nrow = 7)
f9_q <- matrix(c(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                 0,
                 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1), nrow = 9)
f11_q <- matrix(c(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                  0,
                  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1), nrow = 11)

f15_q <- matrix(c(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                  0,
                  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
                  1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1), nrow = 15)

#Queen's vs Rooks case at same neighborhood size ------------------------------

#Queen vs Rooks case, 3x3, sample raster
plot(r1, main = "random raster")
plot(MoranLocal(r1), main = "Queen's case, 3x3, random raster")
plot(MoranLocal(r1, f), main = "Rook's case, 3x3, random raster")

#Queens vs Rooks, 5x5, sample raster
plot(r1, main = "random raster")
plot(MoranLocal(r1, f5_q), main = "Queen's case, 5x5, random raster")
plot(MoranLocal(r1, f5_r), main = "Rook's case, 5x5, random raster")

#Queens vs Rooks, 7x7, sample raster
plot(r1, main = "random raster")
plot(MoranLocal(r1, f7_q), main = "Queen's case, 7x7, random raster")
plot(MoranLocal(r1, f7_r), main = "Rook's case, 7x7, random raster")

#neighborhood size comparison 3, 5, 7 on sample raster ----------------------
#Queen's case 

plot(r1, main = "random raster") 
plot(MoranLocal(r1), main = "Queen's case 3x3, random raster")
plot(MoranLocal(r1,f5_q), main = "Queen's case 5x5, random raster")
plot(MoranLocal(r1,f7_q), main = "Queen's case 7x7, random raster")

#Rook's case 

plot(r1, main = "random raster")
plot(MoranLocal(r1,f3_r), main = "Rook's case 3x3, random raster")
plot(MoranLocal(r1,f5_r), main = "Rook's case 5x5, random raster")
plot(MoranLocal(r1,f7_r), main = "Rook's case 7x7, random raster")

## Neighborhood comparison on my real 2018 NDVI raster data--------------------

ndvi2018 <- raster("ndvi2018.tif")
ra <- st_read("RA_AddedCovariates_prj.shp")

#a resource area in Zambia, pretty small 
sho <- filter(ra, Name == "Shokosha")
sho_r <- crop(ndvi2018, sho)

#Queen's case, neighborhood size comparison

#test on an actual resource area's extent
plot(sho_r, main = "extent of Shokosha (Zambia) \n 76x68, 5168 cells")


q3 <- MoranLocal(sho_r)
plot(q3, main = "3x3 queens")
q5 <- MoranLocal(sho_r, w = f5_q)
plot(q5, main = "5x5 queens")
q7 <- MoranLocal(sho_r, w = f7_q)
plot(q7, main = "7x7 queens")
q9 <- MoranLocal(sho_r, w = f9_q)
plot(q9, main = "9x9 queens")
q11 <- MoranLocal(sho_r, w = f11_q)
plot(q11, main = "11x11 queens")
q15 <- MoranLocal(sho_r, w = f15_q)
plot(q15, main = "15x15 queens")


## Create Final Outputs - ----------------------------------------------
## Moran's I: 3x3, 7x7, 11x11 from NDVI and SAVI all 3 years

## 1994 NDVI -----------------
ndvi1994 <- raster("ndvi1994.tif")

#3x3
Sys.time()
start <- Sys.time()
q3ndvi_94 <- MoranLocal(ndvi1994)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q3ndvi_94, main = "3x3 Moran's I on 1994 NDVI")
writeRaster(q3ndvi_94, "MI_NDVI94_3x3.tif",
                        format = "GTiff",
                        overwrite = TRUE,
                        NAflag = -9999)



#7x7
Sys.time()
start <- Sys.time()
q7ndvi_94 <- MoranLocal(ndvi1994, w = f7_q)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q7ndvi_94, main = "7x7 Moran's I on 1994 NDVI")
writeRaster(q7ndvi_94, "MI_NDVI94_7x7.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)


#11x11
Sys.time()
start <- Sys.time()
q11ndvi_94 <- MoranLocal(ndvi1994, w = f11_q)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q11ndvi_94, main = "11x11 Moran's I on 1994 NDVI")
writeRaster(q11ndvi_94, "MI_NDVI94_11x11.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)

## 2004 NDVI ---------------------------
ndvi2004 <- raster("ndvi2004.tif")

#3x3
Sys.time()
start <- Sys.time()
q3ndvi_04 <- MoranLocal(ndvi2004)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

#plot(q3ndvi_04, main = "3x3 Moran's I on 2004 NDVI")
writeRaster(q3ndvi_04, "MI_NDVI04_3x3.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)



#7x7
Sys.time()
start <- Sys.time()
q7ndvi_04 <- MoranLocal(ndvi2004, w = f7_q)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

#plot(q7ndvi_04, main = "7x7 Moran's I on 2004 NDVI")
writeRaster(q7ndvi_04, "MI_NDVI04_7x7.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)


#11x11
Sys.time()
start <- Sys.time()
q11ndvi_04 <- MoranLocal(ndvi2004, w = f11_q)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

#plot(q11ndvi_04, main = "11x11 Moran's I on 2004 NDVI")
writeRaster(q11ndvi_04, "MI_NDVI04_11x11.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)

# 2018 NDVI------------------------- 

ndvi2018 <- raster("ndvi2018.tif")

#3x3

Sys.time()
start <- Sys.time()
q3ndvi <- MoranLocal(ndvi2018)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q3ndvi, main = "3x3 Moran's I on 2018 NDVI")
writeRaster(q3ndvi, "MI_NDVI18_3x3.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)

#7x7
Sys.time()
start <- Sys.time()
q7ndvi <- MoranLocal(ndvi2018, w = f7_q)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q7ndvi, main = "7x7 Moran's I on 2018 NDVI")
writeRaster(q7ndvi, "MI_NDVI18_7x7.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)

#11x11
Sys.time()
start <- Sys.time()
q11ndvi <- MoranLocal(ndvi2018, w = f11_q)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q11ndvi, main = "11x11 Moran's I on 2018 NDVI")
writeRaster(q11ndvi, "MI_NDVI18_11x11.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)


## 1994 SAVI --------------------------------
savi1994 <- raster("savi1994.tif")

#3x3
Sys.time()
start <- Sys.time()
q3savi_94 <- MoranLocal(savi1994)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q3savi_94, main = "3x3 Moran's I on 1994 SAVI")
writeRaster(q3savi_94, "MI_SAVI94_3x3.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)



#7x7
Sys.time()
start <- Sys.time()
q7savi_94 <- MoranLocal(savi1994, w = f7_q)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q7savi_94, main = "7x7 Moran's I on 1994 SAVI")
writeRaster(q7savi_94, "MI_SAVI94_7x7.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)


#11x11
Sys.time()
start <- Sys.time()
q11savi_94 <- MoranLocal(savi1994, w = f11_q)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q11savi_94, main = "11x11 Moran's I on 1994 SAVI")
writeRaster(q11savi_94, "MI_SAVI94_11x11.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)


## 2004 SAVI ---------------------------

savi2004 <- raster("savi2004.tif")

#3x3
Sys.time()
start <- Sys.time()
q3savi_04 <- MoranLocal(savi2004)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q3savi_04, main = "3x3 Moran's I on 2004 SAVI")
writeRaster(q3savi_04, "MI_SAVI04_3x3.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)



#7x7
Sys.time()
start <- Sys.time()
q7savi_04 <- MoranLocal(savi2004, w = f7_q)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q7savi_04, main = "7x7 Moran's I on 2004 SAVI")
writeRaster(q7savi_04, "MI_SAVI04_7x7.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)


#11x11
Sys.time()
start <- Sys.time()
q11savi_04 <- MoranLocal(savi2004, w = f11_q)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q11savi_04, main = "11x11 Moran's I on 2004 SAVI")
writeRaster(q11savi_04, "MI_SAVI04_11x11.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)


## 2018 SAVI ---------------------------

savi2018 <- raster("savi2018.tif")

#3x3
Sys.time()
start <- Sys.time()
q3savi_18 <- MoranLocal(savi2018)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q3savi_18, main = "3x3 Moran's I on 2018 SAVI")
writeRaster(q3savi_18, "MI_SAVI18_3x3.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)



#7x7
Sys.time()
start <- Sys.time()
q7savi_18 <- MoranLocal(savi2018, w = f7_q)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q7savi_18, main = "7x7 Moran's I on 2018 SAVI")
writeRaster(q7savi_18, "MI_SAVI18_7x7.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)


#11x11
Sys.time()
start <- Sys.time()
q11savi_18 <- MoranLocal(savi2018, w = f11_q)
Sys.time()
end <- Sys.time()
time_taken <- end - start
time_taken

plot(q11savi_18, main = "11x11 Moran's I on 2018 SAVI")
writeRaster(q11savi_18, "MI_SAVI18_11x11.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)