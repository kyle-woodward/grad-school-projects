#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Last Updated: 04/06/2021

@author: Kyle Woodward

- Downloads Significant Historical Volcanic Eruptions Data
- Filters records from 1980 onward plus other cleaning/formatting steps 
- Outputs to .csv and shapefile

The .csv is brought into the main command-line module Landsat_volcanoes.py 
to use for imagery search
"""

# ------------------------------------------------------------------------------ 
import os
import pandas as pd
import geopandas as gpd
import requests
import datetime
import shutil
# ------------------------------------------------------------------------------
def download_eruptions():
    #setup folders, download .zip file and unzip it
    
    wd = os.path.dirname(__file__) #working directory is .py file location
    
    #create src directory
    src_path = os.path.join(wd, "src")
    if not os.path.exists(src_path):
        os.mkdir(src_path)
    
    #create output directory
    output_path = os.path.join(wd,"output")
    if not os.path.exists(output_path):
        os.mkdir(output_path)
    
    #create output\imgs and output\eruptions directories
    folders = ["imgs", "eruptions"]
    for folder in folders:
        new_dir = os.path.join(output_path, folder)
        if not os.path.exists(new_dir):
            os.mkdir(new_dir)
    
    #set "imgs" and "eruptions" folders to variables
    output_eruptions = os.path.join(output_path, "eruptions")
    
    
    #if zip file not already in src folder
    if not os.path.exists(os.path.join(src_path,"Historical_Significant_Volcanic_Eruption_Locations.zip")):
        
        url = 'https://opendata.arcgis.com/datasets/3ed5925b69db4374aec43a054b444214_6.zip?outSR=%7B%22latestWkid%22%3A3857%2C%22wkid%22%3A102100%7D'
        doc = requests.get(url)
        os.chdir(src_path) #change working directory to src folder
        with open('Historical_Significant_Volcanic_Eruption_Locations.zip', 'wb') as f:
            f.write(doc.content) #open and write file contents to src folder
        file = os.path.join(src_path,"Historical_Significant_Volcanic_Eruption_Locations.zip") #full file path of downloaded
        shutil.unpack_archive(file,src_path) #unzip to src folder
    
    #-----------------------------------------------------------------------------------
    
    #Data cleaning and formatting
    
    #Read-in the data using geopandas
    volc = gpd.read_file(os.path.join(src_path,"Historical_Significant_Volcanic_Eruption_Locations.shp"))
    
    #print("original # records:", volc.shape[0])
    volc_notna = volc.dropna(subset=['MO','YEAR','DAY']) #drop records with NaN date values
    #print("after dropping NaN records:", volc_notna.shape[0])
    
    volc_v2 = volc_notna[volc_notna['YEAR'] > 1979] #filtering out eruption occurences before 1980
    #print("after dropping occurences before 1980:", volc_v2.shape[0]) 
    
    #rename all column names for 'to_datetime()' method to read appropriately
    dt_cols = volc_v2[['YEAR', 'MO', 'DAY']].rename(columns={'YEAR':'year', 'MO':'month', 'DAY':'day'})
    #print("renamed cols\n",dt_cols.head(), "\n")
    
    dt_output = pd.to_datetime(dt_cols) #create new datetime Series
    #print("to_datetime\n",dt_output.head())
    volc_v2 = volc_v2.assign(datetime=dt_output) #assign datetime output series to a new column
    
    
    #create new column subset of interest from the dataframe
    volc_newCols = volc_v2[['OBJECTID','YEAR','datetime','COUNTRY','LOCATION','LATITUDE','LONGITUDE','geometry']]
    #print("Total Records:",volc_newCols.shape[0])
    
    # create `start` and `end` columns in datetime format, append as new columns
    dt = volc_newCols['datetime']
    start_date = dt - datetime.timedelta(15)
    end_date = dt + datetime.timedelta(15)
    day_before = dt - datetime.timedelta(1)
    day_after = dt + datetime.timedelta(1)
    
    #assign 'start' and 'end' columns to working dataframe
    volc_final = volc_newCols.assign(start=start_date, 
                                     end=end_date,
                                     day_before=day_before,
                                     day_after=day_after)
    volc_final = volc_final.astype({'start':'string', 
                                    'end':'string', 
                                    'datetime':'string',
                                    'day_before':'string',
                                    'day_after':'string'})
    
    #remove spaces and commas from country names 
    cntry = volc_final['COUNTRY']
    cntry= cntry.replace(" ", "", regex=True).replace(",","", regex=True)
    volc_final = volc_final.assign(COUNTRY=cntry)
    
    # ------------------------------------------------------------------------------
    # Exports
    
    os.chdir(output_eruptions) #change working directory to output\eruptions folder
    volc_final.reset_index(drop=True,inplace=True) #reset index column
    
    #Export eruptions to .csv
    if not os.path.exists(os.path.join(output_eruptions, "eruptions_all.csv")):
        volc_final.to_csv("eruptions_all.csv")
        print("\n eruptions_all.csv saved to {}".format(output_eruptions))
    else:
        print("\n eruptions_all.csv already exists")
    
    #Export eruptions as shapefile
    if not os.path.exists(os.path.join(output_eruptions, "eruptions_all.shp")):
        volc_final.to_file("eruptions_all.shp")
        print("\n eruptions_all.shp saved to {} \n".format(output_eruptions))
    else:
        print("\n eruptions.shp already exists \n")
    