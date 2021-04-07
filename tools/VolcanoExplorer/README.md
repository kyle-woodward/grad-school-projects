# Volcano Explorer
### Author: Kyle Woodward
![beforeAfter](https://user-images.githubusercontent.com/51868526/113901822-3d5b8600-979d-11eb-8756-70e4eb304ec8.jpeg)
The purpose of this tool is to provide an easy, repeatable query/download command-line interface to explore
Landsat imagery in the USGS EarthExplorer archive that have a high chance of capturing volcanic eruptions in action from 1980 onward.

After running the volcano_explorer.py from command-line without any arguments, a cleaned and formatted copy of 
the US Dept of Homeland Secrity's [Historically Significant Volcanic Eruptions dataset](https://hifld-geoplatform.opendata.arcgis.com/datasets/3ed5925b69db4374aec43a054b444214_6?geometry=-127.266%2C-88.438%2C127.266%2C88.438) is saved to the new output\eruptions folder.

Example:\
`python volcano_explorer.py`

The user can then review the eruptions_all.csv or the eruptions_all.shp to determine how they 
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


 _Other search criteria are passed to the landsatxplore API internally, like cloud cover and date range, \
 and the tool will only download imagery if both Before and After images were returned in the search. Therefore, the\
 total number of imagery sets downloaded may be fewer than the max specified by the --number argument._
    
**Ensure that both scripts are stored in the same directory on your computer and run the volcano_explorer.py from command-line.**

