## USAID Project - Download WorldPop Datasets

setwd("C:/USAID/data/worldpop")


base_url <- "ftp://ftp.worldpop.org.uk/GIS/Covariates/Global_2000_2020/" #for WP covariates
base_url2 <- "ftp://ftp.worldpop.org.uk/GIS/Population/Global_2000_2020/" #for WP Population Density

countries <- c("ETH","ZMB")


## SRTM 2000 Elevation
for (country in countries) {
  file_name <- paste0(tolower(country),"_srtm_topo_100m.tif")
  download.file(url=paste0(base_url,country,"/Topo/", file_name), destfile=file_name, method="internal",
                mode = "wb")
}

##Distance to OSM Roads (2016)
for (country in countries) {
  file_name <- paste0(tolower(country),"_osm_dst_road_100m_2016.tif")
  download.file(url=paste0(base_url,country,"/OSM/DST/", file_name), destfile=file_name, method="internal",
                mode = "wb")
}


##Distance to OSM Major Road Intersections
for (country in countries) {
  file_name <- paste0(tolower(country),"_osm_dst_roadintersec_100m_2016.tif")
  download.file(url=paste0(base_url,country,"/OSM/DST/", file_name), destfile=file_name, method="internal",
                mode = "wb")
}


# #Distance to OSM Waterways
for (country in countries) {
  file_name <- paste0(tolower(country),"_osm_dst_waterway_100m_2016.tif")
  download.file(url=paste0(base_url,country,"/OSM/DST/", file_name), destfile=file_name, method="internal",
                mode = "wb")
}


# #Distance to ESA-CCI-LC inland water (2000-2012)
for (country in countries) {
  file_name <- paste0(tolower(country),"_esaccilc_dst_water_100m_2000_2012.tif")
  download.file(url=paste0(base_url,country,"/ESA_CCI_Water/DST/", file_name), destfile=file_name,
                method="internal", mode = "wb")
}


# #Population Density

for (country in countries) {
  file_name <- paste0(tolower(country),"_ppp_2018.tif")
  download.file(url=paste0(base_url2,"2018/", country, "/", file_name), destfile=file_name, method="internal",
                mode = "wb")
}