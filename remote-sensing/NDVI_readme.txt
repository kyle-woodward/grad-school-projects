README 

MODIS data

Downloaded from: https://earlywarning.usgs.gov/fews/datadownloads/East%20Africa/eMODIS%20NDVI%20C6 (Ethiopia)
and from: 	 https://earlywarning.usgs.gov/fews/datadownloads/Southern%20Africa/eMODIS%20NDVI%20C6 (Zambia) 

Downloads and Preprocessing conducted with custom R scripts "MODIS_Preprocess_[Ethiopia/Zambia].r" (separate scripts for each country)

USGS-processed eMODIS monthly product is packaged as three dekadal NDVI files per monthly file download; 250m, WGS84

mean growing season NDVI datasets for each year are in "...MODIS/processed/.../products".
stacks of dekadal NDVI for each year are in "...MODIS/processed/.../stacks".

**layer names in stacks are not preserved in ArcGIS and ENVI when written to disk from R.

Ethiopia final products: MAMJ2007_mean.tif
			 MAMJ2012_mean.tif

Layers in Ethiopia stacks:
March dekad 1
March dekad 2
March dekad 3
April dekad 1
April dekad 2
April dekad 3
May dekad 1
May dekad 2
May dekad 3
June dekad 1
June dekad 2
June dekad 3 

Methods Description: For Ethiopia, the mean of dekadal NDVI rasters (above) were caluclated for the years 2007 and 2012 separately



Zambia final product: ndvi_mean_both_seasons.tif

Layers in Zambia stacks:
October dekad 1
October dekad 2
October dekad 3
November dekad 1
November dekad 2
November dekad 3
December dekad 1
December dekad 2
December dekad 3
January dekad 1
January dekad 2
January dekad 3
February dekad 1
February dekad 2
February dekad 3
March dekad 1
March dekad 2
March dekad 3
April dekad 1
April dekad 2
April dekad 3
May dekad 1
May dekad 2
May dekad 3

Methods Description: For Zambia, the mean of dekadal ndvi rasters (above) were calculated first separately for the 
2012-2013 and 2013-2014 growing season. Then, the mean of these two 2012-2013 and 2013-2014 means were calculated 
to create a 2-year average of growing season NDVI. This was done in two steps to provide 
intermediary datasets - stacks and one-year growing season means - for other potential analyses.


Further Processing details
From the eModis documentation: 

"eMODIS NDVI data are stretched (mapped) linearly (to byte values) as follows:

[-1.0, 1.0] -> [0, 200] - Invalid Values: 201 - 255

NDVI = (value - 100) / 100; example: [(150 - 100) / 100 = 0.5 NDVI]"

I have kept one set of raster stacks with orginial stretched values for reproduceability ("...stretched.tif"),
but these will not be used in analysis.

I have used the above calculation (x -100)/100 to produce NDVI product with valid range [-1.0, 1.0]

 