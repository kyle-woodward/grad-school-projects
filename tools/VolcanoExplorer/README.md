# Volcano Explorer
### Author: Kyle Woodward

The purpose of this script is to provide a dynamic query/download process
for exploring Landsat imagery collected around the same timeframe as the occurrence of
historically significant volcanic eruptions around the world. 

After running the script without any arguments, a cleaned and formatted copy of 
the US Dept of Homeland Secrity's (Historically Significant Volcanic Eruptions dataset)[https://hifld-geoplatform.opendata.arcgis.com/datasets/3ed5925b69db4374aec43a054b444214_6?geometry=-127.266%2C-88.438%2C127.266%2C88.438] is saved to the new output\eruptions folder.

Example:\
`python volcano_explorer.py`

The user can then review this eruptions_all.csv or the eruptions_all.shp to determine how they 
would like to filter their Landsat imagery search, using the optional arugments that filter the dataset on the 'YEAR'
and 'COUNTRY' fields. Any combination of the optional arguments can be used or not used.

Example 1:\
`python volcano_explorer.py -u myusername -p mypassword -sy 2000 -ey 2013 -c NewZealand UnitedStates Nicaragua -n 5`\
Example 2:\
`python volcano_explorer.py -u myusername -p mypassword -sy 2016 -n 5`

Arguments:
* -u --username: EarthExplorer account username (required)
* -p --password: Earth Explorer account password (required)
* -sy --startYear: Start year to filter Landsat imagery search (optional)
* -ey --endYear: End year to filter Landsat imagery search (optional)
* -c --countries: country or list of countries to filter Landsat search (optional)
* -n --number: maximum number* of before/after Landsat imagery sets to download (optional, default=1)


 _the value given to -n argument may not result in that number of imagery sets downloaded.
    Other non-dynamic query criteria are passed to the landsatxplore API to find
    clear images very close to the time of volcanic eruption. THe user may change
    these hard-coded values if they wish._
    
**Ensure that both scripts are stored in the same directory on your computer, and run the volcano_explorer.py script from command-line.**

