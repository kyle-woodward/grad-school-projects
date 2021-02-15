## CHIRPS Precipitation Time Series - Identifying Onset of Dry Season in the Kavango-Zambezi 
## Kyle Woodward

library(raster)
library(rgdal)
library(dplyr)
library(ggplot2)
library(rasterVis)
library(sf)
library(reshape)
library(scales)
library(RColorBrewer)


#load AOI shapefile
AOI <- st_read("EntireAOI_wgs.shp") 

# stack all .tif's from given hydrologic year, output to one multi-layer .tif, load as a rasterBrick
setwd("C:/Thesis/Data/Precipitation")


p94 <- "CHIRPS_1993-4_dekad/raw"
p04 <- "CHIRPS_2003-4_dekad/raw"
p18 <- "CHIRPS_2017-8_dekad/raw"

list_94 <- list.files(p94,
                       full.names = TRUE,
                       pattern = ".tif$")
list_04 <- list.files(p04,
                      full.names = TRUE,
                      pattern = ".tif$")
list_18 <- list.files(p18,
                      full.names = TRUE,
                      pattern = ".tif$")

st94 <- stack(list_94)
st04 <- stack(list_04)
st18 <- stack(list_18)

writeRaster(st94, "CHIRPS_1993-4_dekad/output/dekad_stack.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)
writeRaster(st04, "CHIRPS_2003-4_dekad/output/dekad_stack.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)
writeRaster(st18, "CHIRPS_2017-8_dekad/output/dekad_stack.tif",
            format = "GTiff",
            overwrite = TRUE,
            NAflag = -9999)

st94_df <- as.data.frame(st94, xy = T)
st04_df <- as.data.frame(st04, xy = T)
st18_df <- as.data.frame(st18, xy = T)

#test that AOI is in right spot over Africa

ggplot() +
  geom_raster(data = st94_df, aes(x = x, y = y, fill = chirps.v2.0.1993.09.1)) + 
  scale_fill_gradientn(name = "Precipitation Totals", colors = terrain.colors(10)) +
  geom_sf(data = AOI, color = 'deeppink', fill = 'NA') + coord_sf()

#crop stacks to AOI and output to disk
st94_cropped <- crop(x = st94, y = AOI, 
                       filename = "CHIRPS_1993-4_dekad/output/CHIRPS1993-4stack_crop.tif")
st04_cropped <- crop(x = st04, y = AOI,
                     filename = "CHIRPS_2003-4_dekad/output/CHIRPS2003-4stack_crop.tif")
st18_cropped <- crop(x = st18, y = AOI,
                     filename = "CHIRPS_2017-8_dekad/output/CHIRPS2017-8stackcrop.tif")

names(st94_cropped) <- names(st04_cropped) <- names(st18_cropped) <-
                          c("Sep1", "Sep2", "Sep3", "Oct1", "Oct2", "Oct3", "Nov1", "Nov2", "Nov3",
                           "Dec1", "Dec2", "Dec3", "Jan1", "Jan2", "Jan3", "Feb1", "Feb2", "Feb3",
                           "Mar1", "Mar2", "Mar3", "Apr1", "Apr2", "Apr3,", "May1", "May2", "May3",
                           "Jun1", "Jun2", "Jun3", "Jul1", "Jul2", "Jul3", "Aug1", "Aug2", "Aug3")

st94_cropped_df <- as.data.frame(st94_cropped, xy = TRUE)
st04_cropped_df <- as.data.frame(st04_cropped, xy = TRUE)
st18_cropped_df <- as.data.frame(st18_cropped, xy = TRUE)


#check if new cropped raster data is inside AOI
ggplot() +
  geom_raster(data = st94_cropped_df, aes(x = x, y = y, fill = Sep2)) + 
  scale_fill_gradientn(name = "Precipitation Totals", colors = terrain.colors(10)) +
  geom_sf(data = AOI, color = 'deeppink', fill = 'NA') + coord_sf()

#plot each dekad through time, each dekad its own raster
st94_melt <- melt(data = st94_cropped_df, id.vars = c('x','y'))
st04_melt <- melt(data = st04_cropped_df, id.vars = c('x','y'))
st18_melt <- melt(data = st18_cropped_df, id.vars = c('x','y'))

ggplot() +
  geom_raster(data = st94_melt, aes(x = x, y = y, fill = value)) +
  facet_wrap(~ variable)

#average value of all pixels in every dekad, create new dataframe, rename precip column, 
avg_94 <- cellStats(st94_cropped, mean) %>% as.data.frame()
avg_04 <- cellStats(st04_cropped, mean) %>% as.data.frame()
avg_18 <- cellStats(st18_cropped, mean) %>% as.data.frame()

names(avg_94) <- "Precip94"
names(avg_04) <- "Precip04"
names(avg_18) <- "Precip18"

avg_all <- avg_94 %>% mutate(Precip04 = avg_04$Precip04) %>% mutate(Precip18 = avg_18$Precip18)

#use row.names() to return character string of all row names, append this as a real column 
# dekad_n <- 1:36
avg_all <- avg_all %>% mutate(dekad_n = 1:36) 


#figure for pub
ggplot(avg_all, aes(x= dekad_n), fill = c("Precip94", "Precip04", "Precip18")) +
  geom_line(aes(y = Precip94, colour = "1993-4")) +
  geom_point(aes(y = Precip94, colour = "1993-4")) +
  geom_line(aes(y = Precip04, colour = "2003-4")) +
  geom_point(aes(y = Precip04, colour = "2003-4")) +
  geom_line(aes(y = Precip18, colour = "2017-8")) +
  geom_point(aes(y = Precip18, colour = "2017-8")) +
  xlab("Dekad (September - August)") + ylab("Average Total Rainfall (mm)") +
  theme(text = element_text(size = 15),
        legend.position = "top") +
  scale_colour_manual("Hydrologic Year", values = c("black", "red", "blue"))
  


 

