README

CHIRPS data

monthly precipitation product downloaded from ftp://chg-ftpout.geog.ucsb.edu/pub/org/chg/products/CHIRPS-2.0/ 

R scripts "CHIRPS_Preprocess_(Ethiopia/Tanzania).r" (separate scripts for each country to minimize confusion)
Ethiopia CHIRPS data downloaded manually through the CHIRPS ftp site
Zambia CHIRPS data downloaded inside R script 

resolution = 0.05 degree, WGS84, unit = mm rainfall

mean growing season precipiation in "...CHIRPS/processed/.../products" 
stacks of monthly precipitation in "...CHIRPS/processed/.../stacks"
figures of each dataset in "...CHIRPS/processed/.../figs"


For Ethiopia
stacks contain 4 layers each (months): 
1 March
2 April
3 May
4 June

For Ethiopia, these 4 layers are averaged together for 2007 and 2012 separately to create a 2007 and 2012 
mean growing season precipitation product for each year

Ethiopia final products: S:\USAIDLandesa\DATA\CHIRPS\processed\Ethiopia\products\MAMJ2007_mean.tif
			 S:\USAIDLandesa\DATA\CHIRPS\processed\Ethiopia\products\MAMJ2012_mean.tif


For Zambia
stacks contain 8 layers each (months):
1 October
2 November
3 December
4 January
5 February
6 March
7 April
8 May

For Zambia, all months in each year's growing season were averaged together (October 2012 - May 2013 and October 2013 - May 2014)
to create one 2-year mean growing season precipitation average 

Zambia final product: S:\USAIDLandesa\DATA\CHIRPS\processed\Zambia\products\precip_mean_both_season.tif