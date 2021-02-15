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

d <- st_read("C:/Thesis/Data/ResourceAreas/output/RA_AddedCovariates_prj.shp") %>% 
  rename_at(vars(ends_with("US")), funs(str_replace(., "US", "USE"))) 

ra <- d %>% as.data.frame() %>% select(.,contains("USE"))


#can't do numerical summary of columns that aren't numeric type so first i realize that these columns are factor
lapply(ra, class)

#first create named integer list of the columns that are factors
w <- which(sapply(ra, class) == 'factor')
#then use lapply to convert those columns selected using ra[w] to numeric type
ra[w] <- lapply(ra[w], function(x) as.numeric(as.character(x)))

#replace NA values with 0's and make combined grapple/edible column
ra_NAto0 <- ra %>% mutate_all(funs(replace_na(.,0))) #to add two columns together, have to replace NAs with 0s
GrpEd_USE <- ra_NAto0$Grapple_USE + ra_NAto0$Edible_USE
GrpEd_USE <- GrpEd_USE %>% na_if(., 0) #but want to convert those 0s back to NAs after adding so we excluding NAs/0s in mean calc
ra <- ra %>% add_column(GrpEd_USE)



# will be different summary stats depending on if NAs are converted to 0s, higher stats numbers if NAs are excluded

#make some sort of loop that goes through each "USE" column, does gets some sort of summary stat

#create a dataframe that holds my summary stats of interest from each "USE" field, name columns appropriately-----
# stats <- data.frame(matrix(vector(mode = 'numeric',length = 65), nrow = 13, ncol = 5))
# 
# cnms_from <- c("X1", "X2", "X3", "X4", "X5")
# cnms_to <- c("min", "1q", "median", "3q", "max")
# types <- names(select(ra, ends_with("USE")))

#stats <- stats %>% rename_at(vars(cnms_from), ~cnms_to) %>% add_column(resource = types, .before = 1)

#Approach using findInterval() to assign coded values to original values based on where they fall between quantiles ----

#this works! but is difficult to get all values in interval to hold observations. 
#because the break values are actually exact values themselves, the values get binned in weird ways 
#and some intervals don't get used

#ra_new <- ra
#qt <- sapply(ra, quantile, na.rm = T)
#colnms <- names(ra)

# for (i in colnms) {
#     
#   range <- as.vector(qt[,i]) #get the values of all quantiles for a given resource type from the quantiles df
#     interval <- findInterval(ra_new[,i], range) #assign numeric value to each row based on the numbered position in the interval 
#     newval <-coded[interval] #reassign the interval values to my own coded values 
#     newvar <- paste0(i,"_CAT") #create new variable name for the given resource type 
#     ra_new <- ra_new %>% add_column(newval) %>% rename(!!newvar := newval) #append the new coded values to the dataframe and rename that column
#   }

# range <- as.vector(qt[,i]) 
# interval <- findInterval(ra_new[,i], range)
# newval <-coded[interval]

# #findInterval code example
# ranges    <- c(0, 2.5, 6.5, 10)
# quality   <- c('low', 'medium', 'high')
# 
# 
# values   <- c( 4, 1, 7, 8, 6)
# intervals<- findInterval(values, ranges)
# 
# quality[intervals]

#Approach using the mean of each resource column as a threshold value, coded values will be 0, 1, 2 -------------


m <- sapply(ra, mean, na.rm = T) %>% as.data.frame() %>% rename(., mean = .)

#this for loop takes the mean of a given "_USE" column and uses it as a threshold to recalculate values
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
