#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Last updated: 4/6/2021

@author: Kyle Woodward

The purpose of this script is to provide a dynamic query/download process
for exploring Landsat imagery collected around the same timeframe as the occurrence of
historically significant volcanic eruptions around the world. 

After running the script without any arguments, a cleaned and formatted copy of 
the Historically Significant Volcanic Eruptions dataset from the U.S. Dept 
of Homeland Security is saved to the new output\eruptions folder.

The user can then review this full eruptions dataset to determine how they 
would like to filter their Landsat imagery search, paying attention to the 'YEAR'
and 'COUNTRY' fields.

Arguments:
-u --username: EarthExplorer account username (required)
-p --password: Earth Explorer account password (required)
-sy --startYear: Start year to filter Landsat imagery search (optional)
-ey --endYear: End year to filter Landsat imagery search (optional)
-c --countries: country or list of countries to filter Landsat search (optional)
-n --number: maximum number* of before/after Landsat imagery sets to download (optional, default=1)


* the value given to -n argument may not result in that number of imagery sets downloaded.
    Other non-dynamic query criteria are passed to the landsatxplore API to find
    clear images very close to the time of volcanic eruption. THe user may change
    these hard-coded values if they wish.
    
Ensure that this script and the download_eruptions.py script are stored in the
same directory, and run this script from command-line.


"""

from download_eruptions import download_eruptions 
import os
import pandas
import rasterio as rio
import shutil
import glob
import numpy as np
import matplotlib.pyplot as plt
from landsatxplore.api import API
from landsatxplore.earthexplorer import EarthExplorer
import argparse


download_eruptions() #run the download_eruptions function from download_eruptions.py

# setup paths
wd = os.path.dirname(__file__)
src = os.path.join(wd,"src")
output = os.path.join(wd,"output")
output_eruptions = os.path.join(output,"eruptions")
output_imgs = os.path.join(output, "imgs")

#read-in full eruptions dataset
df = pandas.read_csv(os.path.join(output_eruptions,"eruptions_all.csv"))

def filter_search(startYear, endYear, countries):
    print("Start Year: {} \t End Year: {} \n Countries: {}".format(args.startYear,args.endYear, args.countries))
    
    #if user gives start and end year
    if startYear is not None and endYear is not None:
        #return records between startYear and endYear
        df_sample = df[df['YEAR'].between(args.startYear,args.endYear)]
        
    #if user only gives start year
    elif startYear is not None and endYear is None:
        #return records on or after startYear
        df_sample = df[df['YEAR'] >= args.startYear]
        
    
    #if user only gives end year
    elif startYear is None and endYear is not None:
        #return records on or before endYear
        df_sample = df[df['YEAR'] <= args.endYear] 
        
    #if user gives neither start or end year, pass
    else:
        df_sample = df
        pass
    
    #if user does not give countries list, pass
    if countries is not None:
            #return records in list of countries
        df_sample = df_sample[df_sample['COUNTRY'].isin(list(args.countries))]
    else:
        pass
        
    os.chdir(output_eruptions) #change working directory to output\eruptions folder
    df_sample.reset_index(drop=True,inplace=True)
    
    #Export eruptions to .csv
    df_sample.to_csv("eruptions_sample.csv")
    print("\n filters applied to eruptions_all.csv \n total records in sample: ", df_sample.shape[0])
    print("\n saved as eruptions_sample.csv \n")
    
    
def download_landsat(username,password,number):
    
    df_sample = pandas.read_csv(os.path.join(output_eruptions,"eruptions_sample.csv"))
    
    api = API(username=args.username, password=args.password)
    print('logged into search API')
    ee = EarthExplorer(username=args.username, password=args.password)
    print('logged into EarthExplorer \n')
    
    
    lap=0
    
    #for each volcano eruption record
    for row in df_sample.itertuples(index=False, name='tuple'):
        
        #define search criteria variables from the current records column values
        
        if row.YEAR > 2013: #will use L8 data from 2014 onward, L5 TM for all earlier eruptions
            data = 'landsat_8_c1'
        else:
            data = 'landsat_tm_c1'
        
        location = row.LOCATION    
        lat = row.LATITUDE
        long = row.LONGITUDE
        day_of = row.datetime
        day_before = row.day_before
        day_after = row.day_after
        start = row.start
        end = row.end
        
        #Search for Landsat scenes before eruption and after eruption, storing search results as separate lists
        before_scenes = api.search(
            dataset=data,
            latitude=lat, 
            longitude=long, 
            start_date=start, 
            end_date=day_before, 
            max_cloud_cover=20
        )
        after_scenes = api.search(
                dataset=data,
                latitude=lat, 
                longitude=long, 
                start_date=day_after, 
                end_date=end, 
                max_cloud_cover=20
            )
        
        #if no results are returned for either search, move on to the next eruption record
        if ((len(before_scenes)== 0) or (len(after_scenes)== 0)): 
            pass
        else:
            print(location, day_of)
            
            #before-eruption scenes
            if len(before_scenes) > 0:
                print(f"{len(before_scenes)} scene(s) before eruption found.")
                
                #sort list of scene results ascending by their dict 'acquisition_date' key  
                #take last item in list, giving me latest scene 
                latest_before = sorted(before_scenes, key=lambda k: k['acquisition_date'])[-1]
                print("before eruption latest scene :", latest_before.get('acquisition_date'))
                before_id = latest_before.get('display_id')
                print("scene id:", before_id)
            else:
                pass
    
            #after-eruption scenes
            if len(after_scenes) > 0:
                print(f"{len(after_scenes)} scene(s) after eruption found.")
                
                #sort list of scene results ascending by their dict 'acquisition_date' key  
                #take last item in list, giving me earliest scene      
                earliest_after = sorted(after_scenes, key=lambda k: k['acquisition_date'])[0] 
                print("after eruption earliest scene:", earliest_after.get('acquisition_date'))
                after_id = earliest_after.get('display_id')
                print("scene id:", after_id, "\n")
            else:
                pass
            
            #create new folders for Landsat imagery download
            
            #new parent folder
            parent_name = (location+day_of).replace(" ", "-").replace(":", "-")
            new_parent = os.path.join(output_imgs, parent_name)
            if not os.path.exists(new_parent):
                os.mkdir(new_parent)
            
            #new '/before' and '/after' subfolders in parent folder
            before_subd = os.path.join(new_parent, "before")
            if not os.path.exists(before_subd):
                os.mkdir(before_subd)
            after_subd = os.path.join(new_parent, "after")
            if not os.path.exists(after_subd):
                os.mkdir(after_subd)
            
            #download before landsat image to new '\before' folder
            bfile_name = before_id + ".tar.gz"
            if not os.path.exists(os.path.join(before_subd, bfile_name)):
                print("downloading {} to {}".format(bfile_name, before_subd))
                ee.download(before_id, output_dir = before_subd)
            else:
                print("{} already downloaded \n".format(bfile_name))
            
            #download after landsat image to new '\after' folder
            afile_name = after_id + ".tar.gz"
            if not os.path.exists(os.path.join(after_subd, afile_name)):
                print("downloading {} to {}".format(afile_name, after_subd))
                ee.download(after_id, output_dir = after_subd)
            else:
                print("{} already downloaded \n".format(afile_name))
            
            print("")
            
            lap=lap+1
            if lap==args.numberDownloads:
                break
    
    api.logout()
    ee.logout()
    print("logged out \n")  
    
    
    # ## Step 6: Extract the compressed files in batch with `shutil`.
    
    print("unzipping files...\n")
    rootPath = output_imgs
    parents = os.listdir(rootPath)
    int_dirs = ['after','before']
    
    #loop through each parent ["...\output\imgs\Italy2001..."] and subdirectory ["\before" or "\after"]
    for parent in parents:
        for int_dir in int_dirs:
            
            dir_path = os.path.join(rootPath,parent,int_dir) #construct full path to end dir where image files are
            #print("parent directory\n", dir_path, "\n")
            
            file = os.listdir(dir_path)[0] #select the first file (should be the tar.gz) in that directory
            
            full_file_path = os.path.join(dir_path,file) #create full path to specific tar.gz file
            print("unzipping {}".format(full_file_path), "\n")
            shutil.unpack_archive(full_file_path, dir_path, 'gztar')  #unzip with shutil to same directory     
    
    
    #go into each volcano eruption's parent directory
    for parent in parents:
        #construct full path to the before and after landsat .tif's
        before_path = os.path.join(parent,"before")   
        after_path = os.path.join(parent, "after")
        full_before_path = os.path.join(rootPath,before_path)
        full_after_path = os.path.join(rootPath,after_path)
       
        #if the images are from Landsat 5 (LT05), use bands 4,3,2 for NIR false color
        if os.listdir(full_before_path)[0].split("_")[0] == 'LT05':
        
            #pattern string that will match each band file
            red_search = "*B4.TIF"
            green_search = "*B3.TIF"
            blue_search = "*B2.TIF"
        
        #if images are from Landsat 8 (LC08) use bands 5,4,3 for NIR false color
        elif os.listdir(full_before_path)[0].split("_")[0] == 'LC08':
            
            #pattern string that will match each band file
            red_search = "*B5.TIF"
            green_search = "*B4.TIF"
            blue_search = "*B3.TIF"
        else:
            print("images are not from LT05 or LC08")
            pass
        
        print("reading landsat bands...\n")
        ## BEFORE (B)
        B_red_query = os.path.join(full_before_path, red_search) #construct search criteria string
        B_red_file = glob.glob(B_red_query) #pass search criteria to glob.glob(), returning the band's full filepath
        B_green_query = os.path.join(full_before_path, green_search)
        B_green_file = glob.glob(B_green_query)
        
        B_blue_query = os.path.join(full_before_path, blue_search)
        B_blue_file = glob.glob(B_blue_query)
        
        #open each band's TIF file with rasterio
        B_red_band = rio.open(B_red_file[0])
        B_green_band = rio.open(B_green_file[0])
        B_blue_band = rio.open(B_blue_file[0])
    
        #Read the grid values into numpy arrays
        B_red_array = B_red_band.read(1)
        B_green_array = B_green_band.read(1)
        B_blue_array = B_blue_band.read(1)
    
        #Function to normalize the grid values
        def normalize(array):
            '''Normalizes numpy arrays into scale 0.0 - 1.0'''
            array_min, array_max = array.min(), array.max()
            return ((array - array_min)/(array_max - array_min))
    
        #Normalize the bands using the defined function
        B_redn = normalize(B_red_array)
        B_greenn = normalize(B_green_array)
        B_bluen = normalize(B_blue_array)
     
        B_rgb = np.dstack((B_redn, B_greenn, B_bluen))
        
        ## AFTER (A)
        A_red_query = os.path.join(full_after_path, red_search) #construct search criteria string
        A_red_file = glob.glob(A_red_query) #pass search criteria to glob.glob(), returning the band's full filepath
        A_green_query = os.path.join(full_after_path, green_search)
        A_green_file = glob.glob(A_green_query)
        
        A_blue_query = os.path.join(full_after_path, blue_search)
        A_blue_file = glob.glob(A_blue_query)
        
        #open each band's TIF file with rasterio
        A_red_band = rio.open(A_red_file[0])
        A_green_band = rio.open(A_green_file[0])
        A_blue_band = rio.open(A_blue_file[0])
    
        #Read the grid values into numpy arrays
        A_red_array = A_red_band.read(1)
        A_green_array = A_green_band.read(1)
        A_blue_array = A_blue_band.read(1)
    
    
        #Normalize the bands using the defined normalize function
        A_redn = normalize(A_red_array)
        A_greenn = normalize(A_green_array)
        A_bluen = normalize(A_blue_array)
     
        A_rgb = np.dstack((A_redn, A_greenn, A_bluen))
        
        ## Plot Before and After RGB images
        print("creating Before & After figure... \n")
        rgb_list = [B_rgb,A_rgb] #the two rgb image stacks in a list to call
        
        before_dt = os.listdir(full_before_path)[0].split("_")[3] #creating the datetime string for each image
        after_dt = os.listdir(full_after_path)[0].split("_")[3]
        b_a = [before_dt, after_dt] #putting the two datetime strings in a list to call
        
        fig, axs = plt.subplots(1, 2, figsize=(10, 3))
        for ax, rgb, ba in zip(axs, rgb_list, b_a):
            
            ax.imshow(rgb)
            ax.set_title(ba)
            
        fig.suptitle(parent.split("-00")[0])
        
        #save figure
        figName = os.path.join(rootPath,parent,"beforeAfter.jpg")
        fig.savefig(figName)
        
        #delete fig object from memory
        del fig, axs
        print("")
    
#command line arguments
parser = argparse.ArgumentParser()

parser.add_argument('-u', '--username', type = str, help = 'USGS Earth Explorer username', required = True)
parser.add_argument('-p', '--password', type = str, help = 'USGS Earth Explorer password', required = True)
parser.add_argument('-sy', '--startYear', type = int, help = 'start year for filtered search', required = False)
parser.add_argument('-ey', '--endYear', type = int, help = 'end year for filtered search', required = False)
parser.add_argument('-c','--countries', type = str, nargs='+', help='country or list of countries for filtered search', required=False)
parser.add_argument('-n', '--numberDownloads', type = int, default = 1, help = 'maximum number of before/after imagery sets to download', required = False)

args = parser.parse_args()

#execute functions
filter_search(args.startYear, args.endYear, args.countries)

download_landsat(args.username, args.password, args.numberDownloads)