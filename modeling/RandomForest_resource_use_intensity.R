# Random Forest - Categorical Classification - WP plus top 5 Landsat
#Kyle Woodward

library(rgdal)
library(yaImpute)
library(randomForest)
library(raster)
library(dplyr)
library(sf)
library(ggplot2)

#Predict Grazing  -------------------------------------------

#Load full stack, re-name layers
#will need to edit and re-run PreProcessing.r whenever you decide to change the stack contents

st <- stack("C:/Thesis/Data/Processed/stack/st_classification_v2.tif")

names(st) <- c("edible_bi",                 "fish_bi",                   "grappedible_bi",            "grapple_bi",               
               "graze_bi",                  "lily_bi",                   "med_bi",                    "mud_bi",                   
               "palm_bi",                   "poles_bi",                  "reeds_bi",                  "thatch_bi",                
               "wood_bi",                   "edible_cat",                "fish_cat",                  "grapple_cat",              
               "graze_cat",                 "grped_cat",                 "lily_cat",                  "med_cat",                  
               "mud_cat",                   "palm_cat",                  "poles_cat",                 "reeds_cat",                
               "thatch_cat",                "water_cat",                 "wood_cat",                  "MI_NDVI04_11x11",          
               "MI_NDVI04_3x3",             "MI_NDVI04_7x7",             "MI_NDVI18_11x11",           "MI_NDVI18_3x3",            
               "MI_NDVI18_7x7",             "MI_NDVI94_11x11",           "MI_NDVI94_3x3",             "MI_NDVI94_7x7",            
               "MI_SAVI04_11x11",           "MI_SAVI04_3x3",             "MI_SAVI04_7x7",             "MI_SAVI18_11x11",          
               "MI_SAVI18_3x3",             "MI_SAVI18_7x7",             "MI_SAVI94_11x11",           "MI_SAVI94_3x3",            
               "MI_SAVI94_7x7",             "ndvi_04_18_c",              "ndvi_94_04_c",              "ndvi_94_18_c",             
               "ndvi1994",                  "ndvi2004",                  "ndvi2018",                  "savi_04_18_c",             
               "savi_94_04_c",              "savi_94_18_c",              "savi1994",                  "savi2004",                 
               "savi2018",                  "esaccilc_dst_water_100m",   "osm_dst_road_100m",         "osm_dst_roadintersec_100m",
               "osm_dst_waterway_100m",     "ppp_2018_100m",             "srtm_slope_100m",           "srtm_topo_100m",           
               "countries")    


#keep ndvi_94_04_c, ndvi2004, MI_SAVI04_11x11, savi_94_04_c, MI_NDVI04_11x11
st <- dropLayer(st, c("edible_cat",
                      "edible_bi",
                      "fish_cat",
                      "fish_bi",
                      "grped_cat",
                      "grappedible_bi",
                      "grapple_cat",
                      "grapple_bi",
                      "lily_cat",
                      "lily_bi",
                      "med_cat",
                      "med_bi",
                      "mud_cat",
                      "mud_bi",
                      "palm_cat",
                      "palm_bi",
                      "poles_cat",
                      "poles_bi",
                      "reeds_cat",
                      "reeds_bi",
                      "thatch_cat",
                      "thatch_bi",
                      "wood_cat",
                      "wood_bi",
                      "water_cat",
                      "ppp_2018_100m",
                      "MI_NDVI04_3x3",             "MI_NDVI04_7x7",             "MI_NDVI18_11x11",           "MI_NDVI18_3x3",            
                      "MI_NDVI18_7x7",             "MI_NDVI94_11x11",           "MI_NDVI94_3x3",             "MI_NDVI94_7x7",            
                      "MI_SAVI04_3x3",             "MI_SAVI04_7x7",             "MI_SAVI18_11x11",          
                      "MI_SAVI18_3x3",             "MI_SAVI18_7x7",             "MI_SAVI94_11x11",           "MI_SAVI94_3x3",            
                      "MI_SAVI94_7x7",             "ndvi_04_18_c",              "ndvi_94_18_c",             
                      "ndvi1994",                  "ndvi2018",                  "savi_04_18_c",             
                      "savi_94_18_c",              "savi1994",                  "savi2004",                 
                      "savi2018"))

cell_id = 1:96258
r_df <- as.data.frame(st, xy = TRUE, na.rm = T) %>% mutate(id = cell_id)

set.seed(1771)

#stratify by country
sample_ids_cat <- r_df %>% #to show original class breakdown before 'merge'
  group_by(countries, graze_cat) 
sample_ids_bi <- r_df %>% #we're going to stratify sampling by country and graze_bi
  group_by(countries, graze_bi)

total_tally_cat <- tally(sample_ids_cat) 
total_tally_bi <- tally(sample_ids_bi)

train <- sample_ids_bi %>% sample_frac(0.7) #70% train 30% test
test <- sample_ids_bi %>% subset(., !(id %in% train$id))

train_tally <- tally(train)
test_tally <- tally(test)

#plot training and test pixel sets ----------------------------

ra <- st_read("C:/Thesis/Data/ResourceAreas/output/RA_AddedCovariates_prj.shp")
ggplot() +
  geom_tile(data = train, aes(x = x, y = y, fill = graze_cat)) +
  scale_fill_gradientn(name = "Class Value", colors = c("darkgreen", "red")) +
  ggtitle("Training Pixel Locations \n n = 67381") +
  geom_sf(data = ra, color = 'black', fill = 'NA') + coord_sf()

ggplot() +
  geom_tile(data = test, aes(x = x, y = y, fill = graze_cat)) +
  scale_fill_gradientn(name = "Class Value", colors = c("darkgreen", "red")) +
  ggtitle("Testing Pixel Locations \n n = 28877") +
  geom_sf(data = ra, color = 'black', fill = 'NA') + coord_sf()

#continue modeling--------------------------------------------------
#assign all covariates to x_data, set y_data to the predictor column set as a factor
x_data = train[,5:15]
y_data = (train$graze_cat) %>% as.factor()

test_x <- test[,5:15]
test_y <- test$graze_cat %>% as.factor()

#create calibrated model using tuneRF
tune_fit <- tuneRF(x = x_data, y = y_data, plot = TRUE, 
                   mtryStart = 4, ntreeTry = 500, stepFactor = 1.5, improve = 0.0001,
                   trace = TRUE, sampsize = 800, nodesize = 2, doBest = T)

#getting model fit info
print(tune_fit)
varImpPlot(tune_fit, main = "Variable Importance \n Grazing Categorical Classification \n WP + Top 5 Landsat")

#predict on validation set, assess validation accuracy
validate <- predict(tune_fit, newdata=test_x)
graze_v_accuracy = mean(validate == test$graze_cat)
graze_matrix <- table(validate,test_y) #confusion Matrix
print(graze_matrix)
print(graze_v_accuracy)

##	We are going to save off our RF model:
setwd("C:/Thesis/Data/Analysis/randomforests/RF_cat/WP_top5Landsat/rasters")
graze_cat_RF = tune_fit
save(graze_cat_RF, file="graze_cat_RF.RData")    


#Create prediction raster
#make sure all raster layers match total variables in training data 
st_x <- dropLayer(st, c("graze_cat", "graze_bi", "countries")) #dropping response variables and misc variables

r_pred <- raster::predict(object = st_x, model = tune_fit,
                          filename = "graze_cat_seed1771.tif",
                          ext = extent(st_x), format = "GTiff", overwrite = TRUE, progress = "text")

# Predict Wood Collection ----------------------------------------

st <- stack("C:/Thesis/Data/Processed/stack/st_classification_v2.tif")

names(st) <- c("edible_bi",                 "fish_bi",                   "grappedible_bi",            "grapple_bi",               
               "graze_bi",                  "lily_bi",                   "med_bi",                    "mud_bi",                   
               "palm_bi",                   "poles_bi",                  "reeds_bi",                  "thatch_bi",                
               "wood_bi",                   "edible_cat",                "fish_cat",                  "grapple_cat",              
               "graze_cat",                 "grped_cat",                 "lily_cat",                  "med_cat",                  
               "mud_cat",                   "palm_cat",                  "poles_cat",                 "reeds_cat",                
               "thatch_cat",                "water_cat",                 "wood_cat",                  "MI_NDVI04_11x11",          
               "MI_NDVI04_3x3",             "MI_NDVI04_7x7",             "MI_NDVI18_11x11",           "MI_NDVI18_3x3",            
               "MI_NDVI18_7x7",             "MI_NDVI94_11x11",           "MI_NDVI94_3x3",             "MI_NDVI94_7x7",            
               "MI_SAVI04_11x11",           "MI_SAVI04_3x3",             "MI_SAVI04_7x7",             "MI_SAVI18_11x11",          
               "MI_SAVI18_3x3",             "MI_SAVI18_7x7",             "MI_SAVI94_11x11",           "MI_SAVI94_3x3",            
               "MI_SAVI94_7x7",             "ndvi_04_18_c",              "ndvi_94_04_c",              "ndvi_94_18_c",             
               "ndvi1994",                  "ndvi2004",                  "ndvi2018",                  "savi_04_18_c",             
               "savi_94_04_c",              "savi_94_18_c",              "savi1994",                  "savi2004",                 
               "savi2018",                  "esaccilc_dst_water_100m",   "osm_dst_road_100m",         "osm_dst_roadintersec_100m",
               "osm_dst_waterway_100m",     "ppp_2018_100m",             "srtm_slope_100m",           "srtm_topo_100m",           
               "countries")    


#keep ndvi_04_18_c, savi_04_18_c, ndvi_94_04_c, savi_94_18_c, ndvi_94_18_c
st <- dropLayer(st, c("edible_cat",
                      "edible_bi",
                      "fish_cat",
                      "fish_bi",
                      "grped_cat",
                      "grappedible_bi",
                      "grapple_cat",
                      "grapple_bi",
                      "graze_cat",
                      "graze_bi",
                      "lily_cat",
                      "lily_bi",
                      "med_cat",
                      "med_bi",
                      "mud_cat",
                      "mud_bi",
                      "palm_cat",
                      "palm_bi",
                      "poles_cat",
                      "poles_bi",
                      "reeds_cat",
                      "reeds_bi",
                      "thatch_cat",
                      "thatch_bi",
                      "water_cat",
                      "ppp_2018_100m",
                      "MI_NDVI04_11x11",          
                      "MI_NDVI04_3x3",             "MI_NDVI04_7x7",             "MI_NDVI18_11x11",           "MI_NDVI18_3x3",            
                      "MI_NDVI18_7x7",             "MI_NDVI94_11x11",           "MI_NDVI94_3x3",             "MI_NDVI94_7x7",            
                      "MI_SAVI04_11x11",           "MI_SAVI04_3x3",             "MI_SAVI04_7x7",             "MI_SAVI18_11x11",          
                      "MI_SAVI18_3x3",             "MI_SAVI18_7x7",             "MI_SAVI94_11x11",           "MI_SAVI94_3x3",            
                      "MI_SAVI94_7x7",             
                      "ndvi1994",                  "ndvi2004",                  "ndvi2018",                               
                      "savi_94_04_c",              "savi1994",                  "savi2004",                 
                      "savi2018"))

cell_id = 1:96258
r_df <- as.data.frame(st, xy = TRUE, na.rm = T) %>% mutate(id = cell_id)

set.seed(1771)

#stratify by country
sample_ids_cat <- r_df %>% #to show original class breakdown before 'merge'
  group_by(countries, wood_cat) 
sample_ids_bi <- r_df %>% #we're going to stratify sampling by country and wood_bi
  group_by(countries, wood_bi)

total_tally_cat <- tally(sample_ids_cat) 
total_tally_bi <- tally(sample_ids_bi)

train <- sample_ids_bi %>% sample_frac(0.7) #70% train 30% test
test <- sample_ids_bi %>% subset(., !(id %in% train$id))

train_tally <- tally(train)
test_tally <- tally(test)

#assign all covariates to x_data, set y_data to the predictor column set as a factor
x_data = train[,5:15]
y_data = (train$wood_cat) %>% as.factor()

test_x <- test[,5:15]
test_y <- test$wood_cat %>% as.factor()

#create calibrated model using tuneRF
tune_fit <- tuneRF(x = x_data, y = y_data, plot = TRUE, 
                   mtryStart = 4, ntreeTry = 500, stepFactor = 1.5, improve = 0.0001,
                   trace = TRUE, sampsize = 800, nodesize = 2, doBest = T)

#getting model fit info
print(tune_fit)
varImpPlot(tune_fit, main = "Variable Importance \n Wood Categorical Classification \n WP + Top 5 Landsat")

#predict on validation set, assess validation accuracy
validate <- predict(tune_fit, newdata=test_x)
wood_v_accuracy = mean(validate == test$wood_cat)
wood_matrix <- table(validate,test_y) #confusion Matrix
print(wood_matrix)
print(wood_v_accuracy)

##	We are going to save off our RF model:
setwd("C:/Thesis/Data/Analysis/randomforests/RF_cat/WP_top5Landsat/rasters")
wood_cat_RF = tune_fit
save(wood_cat_RF, file="wood_cat_RF.RData")    


#Create prediction raster
#make sure all raster layers match total variables in training data 
st_x <- dropLayer(st, c("wood_cat", "wood_bi", "countries"))

r_pred <- raster::predict(object = st_x, model = tune_fit,
                          filename = "wood_cat_seed1771.tif",
                          ext = extent(st_x), format = "GTiff", overwrite = TRUE, progress = "text")

#Predict Building Pole Collection ----------------------------------

st <- stack("C:/Thesis/Data/Processed/stack/st_classification_v2.tif")

names(st) <- c("edible_bi",                 "fish_bi",                   "grappedible_bi",            "grapple_bi",               
               "graze_bi",                  "lily_bi",                   "med_bi",                    "mud_bi",                   
               "palm_bi",                   "poles_bi",                  "reeds_bi",                  "thatch_bi",                
               "wood_bi",                   "edible_cat",                "fish_cat",                  "grapple_cat",              
               "graze_cat",                 "grped_cat",                 "lily_cat",                  "med_cat",                  
               "mud_cat",                   "palm_cat",                  "poles_cat",                 "reeds_cat",                
               "thatch_cat",                "water_cat",                 "wood_cat",                  "MI_NDVI04_11x11",          
               "MI_NDVI04_3x3",             "MI_NDVI04_7x7",             "MI_NDVI18_11x11",           "MI_NDVI18_3x3",            
               "MI_NDVI18_7x7",             "MI_NDVI94_11x11",           "MI_NDVI94_3x3",             "MI_NDVI94_7x7",            
               "MI_SAVI04_11x11",           "MI_SAVI04_3x3",             "MI_SAVI04_7x7",             "MI_SAVI18_11x11",          
               "MI_SAVI18_3x3",             "MI_SAVI18_7x7",             "MI_SAVI94_11x11",           "MI_SAVI94_3x3",            
               "MI_SAVI94_7x7",             "ndvi_04_18_c",              "ndvi_94_04_c",              "ndvi_94_18_c",             
               "ndvi1994",                  "ndvi2004",                  "ndvi2018",                  "savi_04_18_c",             
               "savi_94_04_c",              "savi_94_18_c",              "savi1994",                  "savi2004",                 
               "savi2018",                  "esaccilc_dst_water_100m",   "osm_dst_road_100m",         "osm_dst_roadintersec_100m",
               "osm_dst_waterway_100m",     "ppp_2018_100m",             "srtm_slope_100m",           "srtm_topo_100m",           
               "countries")    


#keep savi2004, ndvi2004, ndvi_94_04_c, ndvi_04_18_c, savi_94_04_c
st <- dropLayer(st, c("edible_cat",
                      "edible_bi",
                      "fish_cat",
                      "fish_bi",
                      "grped_cat",
                      "grappedible_bi",
                      "grapple_cat",
                      "grapple_bi",
                      "graze_cat",
                      "graze_bi",
                      "lily_cat",
                      "lily_bi",
                      "med_cat",
                      "med_bi",
                      "mud_cat",
                      "mud_bi",
                      "palm_cat",
                      "palm_bi",
                      "reeds_cat",
                      "reeds_bi",
                      "thatch_cat",
                      "thatch_bi",
                      "wood_cat",
                      "wood_bi",
                      "water_cat",
                      "ppp_2018_100m",
                      "MI_NDVI04_11x11",          
                      "MI_NDVI04_3x3",             "MI_NDVI04_7x7",             "MI_NDVI18_11x11",           "MI_NDVI18_3x3",            
                      "MI_NDVI18_7x7",             "MI_NDVI94_11x11",           "MI_NDVI94_3x3",             "MI_NDVI94_7x7",            
                      "MI_SAVI04_11x11",           "MI_SAVI04_3x3",             "MI_SAVI04_7x7",             "MI_SAVI18_11x11",          
                      "MI_SAVI18_3x3",             "MI_SAVI18_7x7",             "MI_SAVI94_11x11",           "MI_SAVI94_3x3",            
                      "MI_SAVI94_7x7",             "ndvi_94_18_c",             
                      "ndvi1994",                  "ndvi2018",                  "savi_04_18_c",             
                      "savi_94_18_c",              "savi1994",                 
                      "savi2018"))

cell_id = 1:96258
r_df <- as.data.frame(st, xy = TRUE, na.rm = T) %>% mutate(id = cell_id)

set.seed(1771)

#stratify by country
sample_ids_cat <- r_df %>% #to show original class breakdown before 'merge'
  group_by(countries, poles_cat) 
sample_ids_bi <- r_df %>% #we're going to stratify sampling by country and poles_bi
  group_by(countries, poles_bi)

total_tally_cat <- tally(sample_ids_cat) 
total_tally_bi <- tally(sample_ids_bi)

train <- sample_ids_bi %>% sample_frac(0.7) #70% train 30% test
test <- sample_ids_bi %>% subset(., !(id %in% train$id))

train_tally <- tally(train)
test_tally <- tally(test)

#assign all covariates to x_data, set y_data to the predictor column set as a factor
x_data = train[,5:15]
y_data = (train$poles_cat) %>% as.factor()

test_x <- test[,5:15]
test_y <- test$poles_cat %>% as.factor()

#create calibrated model using tuneRF
tune_fit <- tuneRF(x = x_data, y = y_data, plot = TRUE, 
                   mtryStart = 4, ntreeTry = 500, stepFactor = 1.5, improve = 0.0001,
                   trace = TRUE, sampsize = 800, nodesize = 2, doBest = T)

#getting model fit info
print(tune_fit)
varImpPlot(tune_fit, main = "Variable Importance \n Poles Categorical Classification \n WP + Top 5 Landsat")

#predict on validation set, assess validation accuracy
validate <- predict(tune_fit, newdata=test_x)
poles_v_accuracy = mean(validate == test$poles_cat)
poles_matrix <- table(validate,test_y) #confusion Matrix
print(poles_matrix)
print(poles_v_accuracy)

##	We are going to save off our RF model:
setwd("C:/Thesis/Data/Analysis/randomforests/RF_cat/WP_top5Landsat/rasters")
poles_cat_RF = tune_fit
save(poles_cat_RF, file="poles_cat_RF.RData")    


#Create prediction raster
#make sure all raster layers match total variables in training data 
st_x <- dropLayer(st, c("poles_cat", "poles_bi", "countries"))

r_pred <- raster::predict(object = st_x, model = tune_fit,
                          filename = "poles_cat_seed1771.tif",
                          ext = extent(st_x), format = "GTiff", overwrite = TRUE, progress = "text")

# Predict Thatch ------------------------------------------

st <- stack("C:/Thesis/Data/Processed/stack/st_classification_v2.tif")

names(st) <- c("edible_bi",                 "fish_bi",                   "grappedible_bi",            "grapple_bi",               
               "graze_bi",                  "lily_bi",                   "med_bi",                    "mud_bi",                   
               "palm_bi",                   "poles_bi",                  "reeds_bi",                  "thatch_bi",                
               "wood_bi",                   "edible_cat",                "fish_cat",                  "grapple_cat",              
               "graze_cat",                 "grped_cat",                 "lily_cat",                  "med_cat",                  
               "mud_cat",                   "palm_cat",                  "poles_cat",                 "reeds_cat",                
               "thatch_cat",                "water_cat",                 "wood_cat",                  "MI_NDVI04_11x11",          
               "MI_NDVI04_3x3",             "MI_NDVI04_7x7",             "MI_NDVI18_11x11",           "MI_NDVI18_3x3",            
               "MI_NDVI18_7x7",             "MI_NDVI94_11x11",           "MI_NDVI94_3x3",             "MI_NDVI94_7x7",            
               "MI_SAVI04_11x11",           "MI_SAVI04_3x3",             "MI_SAVI04_7x7",             "MI_SAVI18_11x11",          
               "MI_SAVI18_3x3",             "MI_SAVI18_7x7",             "MI_SAVI94_11x11",           "MI_SAVI94_3x3",            
               "MI_SAVI94_7x7",             "ndvi_04_18_c",              "ndvi_94_04_c",              "ndvi_94_18_c",             
               "ndvi1994",                  "ndvi2004",                  "ndvi2018",                  "savi_04_18_c",             
               "savi_94_04_c",              "savi_94_18_c",              "savi1994",                  "savi2004",                 
               "savi2018",                  "esaccilc_dst_water_100m",   "osm_dst_road_100m",         "osm_dst_roadintersec_100m",
               "osm_dst_waterway_100m",     "ppp_2018_100m",             "srtm_slope_100m",           "srtm_topo_100m",           
               "countries")    


#keep ndvi_94_04_c, savi_94_04_c, MI_SAVI04_11x11, MI_NDVI04_11x11, savi_04_18_c
st <- dropLayer(st, c("edible_cat",
                      "edible_bi",
                      "fish_cat",
                      "fish_bi",
                      "grped_cat",
                      "grappedible_bi",
                      "grapple_cat",
                      "grapple_bi",
                      "graze_cat",
                      "graze_bi",
                      "lily_cat",
                      "lily_bi",
                      "med_cat",
                      "med_bi",
                      "mud_cat",
                      "mud_bi",
                      "palm_cat",
                      "palm_bi",
                      "poles_cat",
                      "poles_bi",
                      "reeds_cat",
                      "reeds_bi",
                      "wood_cat",
                      "wood_bi",
                      "water_cat",
                      "ppp_2018_100m",
                      "MI_NDVI04_3x3",             "MI_NDVI04_7x7",             "MI_NDVI18_11x11",           "MI_NDVI18_3x3",            
                      "MI_NDVI18_7x7",             "MI_NDVI94_11x11",           "MI_NDVI94_3x3",             "MI_NDVI94_7x7",            
                      "MI_SAVI04_3x3",             "MI_SAVI04_7x7",             "MI_SAVI18_11x11",          
                      "MI_SAVI18_3x3",             "MI_SAVI18_7x7",             "MI_SAVI94_11x11",           "MI_SAVI94_3x3",            
                      "MI_SAVI94_7x7",             "ndvi_04_18_c",              "ndvi_94_18_c",             
                      "ndvi1994",                  "ndvi2004",                  "ndvi2018",                               
                      "savi_94_18_c",              "savi1994",                  "savi2004",                 
                      "savi2018"))

cell_id = 1:96258
r_df <- as.data.frame(st, xy = TRUE, na.rm = T) %>% mutate(id = cell_id)

set.seed(1771)

#stratify by country
sample_ids_cat <- r_df %>% #to show original class breakdown before 'merge'
  group_by(countries, thatch_cat) 
sample_ids_bi <- r_df %>% #we're going to stratify sampling by country and thatch_bi
  group_by(countries, thatch_bi)

total_tally_cat <- tally(sample_ids_cat) 
total_tally_bi <- tally(sample_ids_bi)

train <- sample_ids_bi %>% sample_frac(0.7) #70% train 30% test
test <- sample_ids_bi %>% subset(., !(id %in% train$id))

train_tally <- tally(train)
test_tally <- tally(test)

#assign all covariates to x_data, set y_data to the predictor column set as a factor
x_data = train[,5:15]
y_data = (train$thatch_cat) %>% as.factor()

test_x <- test[,5:15]
test_y <- test$thatch_cat %>% as.factor()

#create calibrated model using tuneRF
tune_fit <- tuneRF(x = x_data, y = y_data, plot = TRUE, 
                   mtryStart = 4, ntreeTry = 500, stepFactor = 1.5, improve = 0.0001,
                   trace = TRUE, sampsize = 800, nodesize = 2, doBest = T)

#getting model fit info
print(tune_fit)
varImpPlot(tune_fit, main = "Variable Importance \n Thatch Categorical Classification \n WP + Top 5 Landsat")

#predict on validation set, assess validation accuracy
validate <- predict(tune_fit, newdata=test_x)
thatch_v_accuracy = mean(validate == test$thatch_cat)
thatch_matrix <- table(validate,test_y) #confusion Matrix
print(thatch_matrix)
print(thatch_v_accuracy)

##	We are going to save off our RF model:
setwd("C:/Thesis/Data/Analysis/randomforests/RF_cat/WP_top5Landsat/rasters")
thatch_cat_RF = tune_fit
save(thatch_cat_RF, file="thatch_cat_RF.RData")    


#Create prediction raster
#make sure all raster layers match total variables in training data 
st_x <- dropLayer(st, c("thatch_cat", "thatch_bi", "countries"))

r_pred <- raster::predict(object = st_x, model = tune_fit,
                          filename = "thatch_cat_seed1771.tif",
                          ext = extent(st_x), format = "GTiff", overwrite = TRUE, progress = "text")

# Predict Grapple/Edible Collection ---------------------------------

st <- stack("C:/Thesis/Data/Processed/stack/st_classification_v2.tif")

names(st) <- c("edible_bi",                 "fish_bi",                   "grappedible_bi",            "grapple_bi",               
               "graze_bi",                  "lily_bi",                   "med_bi",                    "mud_bi",                   
               "palm_bi",                   "poles_bi",                  "reeds_bi",                  "thatch_bi",                
               "wood_bi",                   "edible_cat",                "fish_cat",                  "grapple_cat",              
               "graze_cat",                 "grped_cat",                 "lily_cat",                  "med_cat",                  
               "mud_cat",                   "palm_cat",                  "poles_cat",                 "reeds_cat",                
               "thatch_cat",                "water_cat",                 "wood_cat",                  "MI_NDVI04_11x11",          
               "MI_NDVI04_3x3",             "MI_NDVI04_7x7",             "MI_NDVI18_11x11",           "MI_NDVI18_3x3",            
               "MI_NDVI18_7x7",             "MI_NDVI94_11x11",           "MI_NDVI94_3x3",             "MI_NDVI94_7x7",            
               "MI_SAVI04_11x11",           "MI_SAVI04_3x3",             "MI_SAVI04_7x7",             "MI_SAVI18_11x11",          
               "MI_SAVI18_3x3",             "MI_SAVI18_7x7",             "MI_SAVI94_11x11",           "MI_SAVI94_3x3",            
               "MI_SAVI94_7x7",             "ndvi_04_18_c",              "ndvi_94_04_c",              "ndvi_94_18_c",             
               "ndvi1994",                  "ndvi2004",                  "ndvi2018",                  "savi_04_18_c",             
               "savi_94_04_c",              "savi_94_18_c",              "savi1994",                  "savi2004",                 
               "savi2018",                  "esaccilc_dst_water_100m",   "osm_dst_road_100m",         "osm_dst_roadintersec_100m",
               "osm_dst_waterway_100m",     "ppp_2018_100m",             "srtm_slope_100m",           "srtm_topo_100m",           
               "countries")    

#keep savi2004, ndvi2004, savi_94_04_c, ndvi_94_04_c, ndvi_04_18_c
st <- dropLayer(st, c("edible_cat",
                      "edible_bi",
                      "fish_cat",
                      "fish_bi",
                      "grapple_cat",
                      "grapple_bi",
                      "graze_cat",
                      "graze_bi",
                      "lily_cat",
                      "lily_bi",
                      "med_cat",
                      "med_bi",
                      "mud_cat",
                      "mud_bi",
                      "palm_cat",
                      "palm_bi",
                      "poles_cat",
                      "poles_bi",
                      "reeds_cat",
                      "reeds_bi",
                      "thatch_cat",
                      "thatch_bi",
                      "wood_cat",
                      "wood_bi",
                      "water_cat",
                      "ppp_2018_100m",
                      "MI_NDVI04_11x11",          
                      "MI_NDVI04_3x3",             "MI_NDVI04_7x7",             "MI_NDVI18_11x11",           "MI_NDVI18_3x3",            
                      "MI_NDVI18_7x7",             "MI_NDVI94_11x11",           "MI_NDVI94_3x3",             "MI_NDVI94_7x7",            
                      "MI_SAVI04_11x11",           "MI_SAVI04_3x3",             "MI_SAVI04_7x7",             "MI_SAVI18_11x11",          
                      "MI_SAVI18_3x3",             "MI_SAVI18_7x7",             "MI_SAVI94_11x11",           "MI_SAVI94_3x3",            
                      "MI_SAVI94_7x7",             "ndvi_94_18_c",             
                      "ndvi1994",                  "ndvi2018",                  "savi_04_18_c",             
                      "savi_94_18_c",              "savi1994",                            
                      "savi2018"))

cell_id = 1:96258
r_df <- as.data.frame(st, xy = TRUE, na.rm = T) %>% mutate(id = cell_id)

set.seed(1771)

#stratify by country
sample_ids_cat <- r_df %>% #to show original class breakdown before 'merge'
  group_by(countries, grped_cat) 
sample_ids_bi <- r_df %>% #we're going to stratify sampling by country and grappedible_bi
  group_by(countries, grappedible_bi)

total_tally_cat <- tally(sample_ids_cat) 
total_tally_bi <- tally(sample_ids_bi)

train <- sample_ids_bi %>% sample_frac(0.7) #70% train 30% test
test <- sample_ids_bi %>% subset(., !(id %in% train$id))

train_tally <- tally(train)
test_tally <- tally(test)

#assign all covariates to x_data, set y_data to the predictor column set as a factor
x_data = train[,5:15]
y_data = (train$grped_cat) %>% as.factor()

test_x <- test[,5:15]
test_y <- test$grped_cat %>% as.factor()

#create calibrated model using tuneRF
tune_fit <- tuneRF(x = x_data, y = y_data, plot = TRUE, 
                   mtryStart = 4, ntreeTry = 500, stepFactor = 1.5, improve = 0.0001,
                   trace = TRUE, sampsize = 800, nodesize = 2, doBest = T)

#getting model fit info
print(tune_fit)
varImpPlot(tune_fit, main = "Variable Importance \n Grapple Edible Categorical Classification \n WP + Top 5 Landsat")

#predict on validation set, assess validation accuracy
validate <- predict(tune_fit, newdata=test_x)
grped_v_accuracy = mean(validate == test$grped_cat)
grped_matrix <- table(validate,test_y) #confusion Matrix
print(grped_matrix)
print(grped_v_accuracy)

##	We are going to save off our RF model:
setwd("C:/Thesis/Data/Analysis/randomforests/RF_cat/WP_top5Landsat/rasters")
grped_cat_RF = tune_fit
save(grped_cat_RF, file="grped_cat_RF.RData")    


#Create prediction raster
#make sure all raster layers match total variables in training data 
st_x <- dropLayer(st, c("grped_cat", "grappedible_bi", "countries"))

r_pred <- raster::predict(object = st_x, model = tune_fit,
                          filename = "grped_cat_seed1771.tif",
                          ext = extent(st_x), format = "GTiff", overwrite = TRUE, progress = "text")

