''' Mosaic SD2014 image sub-tiles for each tile (e.g. tile1_subtile1, tile1_subtile2)
        rasterio method
        Kyle Woodward                                                 '''
import os
import rasterio
from rasterio.merge import merge
from rasterio.plot import show
import gdal
import matplotlib
from matplotlib import pyplot
import glob
import numpy as np
get_ipython().run_line_magic('matplotlib', 'inline')


#Setup in and out paths

in_path = r"SD2014_subtile_extracts"
out_path = r"SD2014_whole_tile_mosaics"

#list of the tile ID numbers to mosaic
tile_id = [9,10,12,13]

for i in tile_id:
    
    file_name = "SD2014_tile" + str(i) + "_mosaic.tif"
    print("file_name will be", file_name)
    print("")

    #full output file path name
    out_fn = os.path.join(out_path, file_name)
    print("full file path will be" ,out_fn)
    print("")

    #make search criteria for glob function
    search_criteria_string = "SD2014_extract_tile" + str(i) + "*.TIF.tif"
    print("using search_criteria_string: ", search_criteria_string)
    print("")
    search_criteria = search_criteria_string
    q = os.path.join(in_path, search_criteria)
    print("search criteria result: ", q)
    print("")

    #use glob to find the right files
    tile_fps = glob.glob(q)
    print("files found: ", tile_fps)
    print("")
    
    ## Iterate through the files listed in glob, store in a list to read and mosaic with rasterio ##

    # First create a list for the source raster datafiles (in read mode) to open with rasterio        
    src_files_to_mosaic = []

    # Iterate over raster files and add them to the source - list in 'read mode'
    for fp in tile_fps:
        src = rasterio.open(fp)
        src_files_to_mosaic.append(src)
    
    print("successful opening files: ", src_files_to_mosaic)
    print("")
    
    # Merge function returns a single mosaic array and the transformation info
    print("Mosaicking")
    mosaic, out_trans = merge(src_files_to_mosaic)

    # Plot the result
    show(mosaic)
    
    # Copy the metadata
    out_meta = src.meta.copy()
    print("printing metadata: " , "/", out_meta)
    #Update the metadata
    out_meta.update({"driver": "GTiff",
                     "height": mosaic.shape[1],
                     "width": mosaic.shape[2],
                     "transform": out_trans
                     }
                    )

    # Write the mosaic raster to disk
    print("writing", file_name, "to disk")
    with rasterio.open(out_fn, "w", **out_meta) as dest:
        dest.write(mosaic)
    
    print("")
    print("Next mosaic...")
    print("")
    break #comment out to run the whole list of tiles





