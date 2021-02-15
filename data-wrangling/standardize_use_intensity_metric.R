## Create Categorical Resource Use Intensity Values for the Resource Area Dataset
## Kyle Woodward

library(sf)
library(dplyr)
library(tidyr)
library(rgdal)
library(tibble)
library(stringr)


#read-in resource area shapefile, select only the OBJECTID, "_USE", and geometry columns
#had to change names of two columns to fit the "_USE" naming scheme

d <- st_read("RA_AddedCovariates_prj.shp") %>% 
  rename_at(vars(ends_with("US")), funs(str_replace(., "US", "USE"))) 

ra <- d %>% as.data.frame() %>% select(.,contains("USE"))


#check whether these columns are factor type
lapply(ra, class)

#first create named integer list of the columns that are factors
w <- which(sapply(ra, class) == 'factor')
#then use lapply to convert those columns selected using ra[w] to numeric type
ra[w] <- lapply(ra[w], function(x) as.numeric(as.character(x)))

#replace NA values with 0's and make combined grapple/edible column
ra_NAto0 <- ra %>% mutate_all(funs(replace_na(.,0))) #to add two columns together, have to replace NAs with 0s
GrpEd_USE <- ra_NAto0$Grapple_USE + ra_NAto0$Edible_USE
GrpEd_USE <- GrpEd_USE %>% na_if(., 0) 
#but want to convert those 0s back to NAs after adding to exclude NAs/0s in mean calc
ra <- ra %>% add_column(GrpEd_USE)

#Create coded values 0, 1, 2 to represent 'NA', < mean, and > mean -------------

m <- sapply(ra, mean, na.rm = T) %>% as.data.frame() %>% rename(., mean = .)

#takes the mean of a given "_USE" column and uses it as a threshold to recalculate values
#resource areas with "_USE" value below its mean assigned a 1, if above its mean a 2, and all NA's are replaced to 0
#new vector of coded values are appended as new "_CAT" columns which i can use to create predictor rasters
resource <- names(ra)
for (i in resource) {
  threshold <- m[i,]
  newval <- ifelse(ra[,i] < threshold, 1, 2) %>% replace_na(.,0)
  v = unlist(strsplit(i, split='_', fixed=TRUE))[1]
  newvar <- paste0(v,"_CAT")
  d <- d %>% add_column(newval) %>% rename(!!newvar := newval)
}


setwd("C:/Thesis/Data/ResourceAreas/output")
st_write(d, "ra_use_cat.shp")
