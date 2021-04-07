#!/usr/bin/env python
# coding: utf-8

#    Extract bright impervious surfaces in residential areas, processed by SD2014 image tile (n =12)
#            Results in one raster mask per SD2014 image tile where 1 = bright impervious, 0 = other
#         
#         Workflow (constantly changing):
#         1. Create tile subset featureclasses(FC) from original LAND_USE_2015 and Parcels shapefiles(n=24) 
#         2. Create Right-of-Way (ROW) and Residential (RES) land use FC's from each tile's LAND_USE FC
#         3. For each tile's Parcels FC, create large and small residential parcels FC's based
#             on parcel size and its intersection w/ RES FC
#         4. Select SmResParcels and LgResParcels that intersect ROW FC's, buffer the query result
#         5. Union and Dissolve the orignal SmResParcels and LgResParcels to their ROWintersectBuffer from 
#             previous step
#         6. Extract by Mask the BGR threshold raster to this final AOI

# In[1]:


## Importing modules and setting up directories 

import time
from time import time, ctime
import os
import arcpy
from arcpy.sa import *
import glob

arcpy.env.overwriteOutput = True
arcpy.CheckOutExtension("Spatial")
arcpy.env.parallelProcessingFactor = "2" #allows parallel processing across cores

#create path to root directory
root_dir = ('D:\EnviroAtlas\MULC_SanDiego\intermediate_data\FinalAttempt_ReclassSoilImperv')

#create new output directory to save final products in \final and intermediate products in \scratch
#make the directories if they don't exist
out_dir = os.path.join(root_dir, 'output')
if not os.path.exists(out_dir):
    os.makedirs(out_dir)
    
end_dir = ('final', 'scratch')
for d in end_dir:
    if not os.path.exists(os.path.join(out_dir, d)):
        os.makedirs(os.path.join(out_dir, d))

#create end directory objects to call in the arcpy tools
final_dir = os.path.join(out_dir, 'final')
scratch_dir = os.path.join(out_dir, 'scratch')

#create scratch geodatabase in the scratch directory for all intermediate featureclasses created
scratch_gdb_path = os.path.join(scratch_dir, 'scratch.gdb')
if not os.path.exists(scratch_gdb_path):
    arcpy.CreateFileGDB_management(scratch_dir, 'scratch.gdb')

#provide path to thematic data
parcels_src = 'D:\EnviroAtlas\MULC_SanDiego\intermediate_data\SanDiego_ThematicInputs\Parcels.shp'
land_use_src = 'D:\EnviroAtlas\MULC_SanDiego\intermediate_data\SANDAG_LandUseData\LAND_USE_2015.shp'

#provide path to the (B+G)-R threshold raster masks
BGR_masks = 'D:\EnviroAtlas\MULC_SanDiego\intermediate_data\FinalAttempt_ReclassSoilImperv\SD2014_BGminusR_masks'


# In[2]:


#import Parcels and LAND_USE_2015 shapefiles from source folder into scratch geodatabase

parcels_FC_path = os.path.join(scratch_gdb_path, "Parcels")
land_use_FC_path = os.path.join(scratch_gdb_path, "LAND_USE_2015")

#Parcels.shp to GDB
if arcpy.Exists(parcels_FC_path):
    print("Parcels already exists in the gdb")
else:
    arcpy.FeatureClassToGeodatabase_conversion(parcels_src, scratch_gdb_path)  
#LAND_USE_2015.shp to GDB
if arcpy.Exists(land_use_FC_path):
    print("LAND_USE_2015 already exists in the gdb")
else:
    arcpy.FeatureClassToGeodatabase_conversion(land_use_src, scratch_gdb_path)  


# In[3]:


'''             1a. Creating Parcels and LAND_USE_2015 subsets by tile...

        Convert the BGR raster masks to polygon to use as the Intersect feature in a Select by Location function
                                        
                                        result = 12 new FC's

                                    NAMING SCHEME = tile{}extentPoly'''

arcpy.env.workspace = BGR_masks

ras_list = arcpy.ListRasters()

for ras in ras_list:
    #make base name to append to output directory
    ras_string = ras
    outName = (ras_string.split(".")[0]).split("R_")[1] + "extentPoly"
    outPath = os.path.join(scratch_gdb_path, outName)

    if arcpy.Exists(outPath):
        print(outName, "already exists in the gdb \n")
    else:
        start = time.time()
        print("start time:", ctime(start))
        print("converting", ras, "to integer type")
        inras = Int(Raster(ras)*0) #to create a 1-value integer raster mask
        print("executing Raster to Polygon conversion, saving as", outName)
        arcpy.RasterToPolygon_conversion(inras, outPath, "NO_SIMPLIFY", "Value", "MULTIPLE_OUTER_PART")
        end = time.time()
        print("time elapsed:", (end-start)/60, "minutes \n")
    #break


# In[4]:


'''                 1b. Creating Parcels and LAND_USE_2015 subsets by tile...

            Execute a Select by Location for LAND_USE_2015 and Parcels feature classes that intersect 
                each tile{}_extentPoly then save as new gdb featureclass so we can do the geoprocessing 
                    steps with smaller subsets (n=12) of data
                                        
                                        result = 24 new FC's
                                        
                                            NAMING SCHEME
                                        tile{}_LAND_USE_2015
                                        tile{}_Parcels        

                                                         '''

arcpy.env.workspace = scratch_gdb_path

LUFC = 'LAND_USE_2015'
ParcelsFC = 'Parcels'

extentPoly_list = arcpy.ListFeatureClasses("*extentPoly")
for exPoly in extentPoly_list:

    clipFC = exPoly
    
    LU_out_name = exPoly.split("extent")[0] + "_" + LUFC
    LU_outFC = os.path.join(scratch_gdb_path, LU_out_name)
    
    Parcels_out_name = exPoly.split("extent")[0] + "_" + ParcelsFC
    Parcels_outFC = os.path.join(scratch_gdb_path, Parcels_out_name)
    
    ############  Creating LAND_USE_2015 subsets by tile  #############
    if arcpy.Exists(LU_outFC):
            print(LU_out_name, "already exists \n")
    else:
        #clip
        start = time.time()
        print("start time:", ctime(start))
        print("Clipping ", LUFC, "to", clipFC)
        LU_clip = arcpy.Clip_analysis(LUFC, clipFC, LU_outFC)
        end = time.time()
        print("saved to:", LU_outFC)
        print("time elapsed: ", (end-start)/60, "minutes \n")
        
    
    ############  Creating Parcels subsets by tile #################    
    if arcpy.Exists(Parcels_outFC):
            print(Parcels_out_name, "already exists \n")
    else:
        #clip
        start = time.time()
        print("start time:", ctime(start))
        print("Clipping ", ParcelsFC, "to", clipFC)
        Parcels_clip = arcpy.Clip_analysis(ParcelsFC, clipFC, Parcels_outFC)
        end = time.time()
        print("saved to:", Parcels_out_name)
        print("time elapsed: ", (end-start)/60, "minutes \n")  


# In[5]:


''' 2. Create Right-of-Way (ROW) and Residential (RES) subset featureclasses from LAND_USE_2015 dataset for 
        each tile set
                                        
                                        result = 24 new FC's
                                        
                                        NAMING SCHEME
                                        tile{}_ROW
                                        tile{}_RES                    '''


arcpy.env.workspace = scratch_gdb_path

LU_subsets = arcpy.ListFeatureClasses("tile*LAND_USE_2015")

for LU in LU_subsets:
    
    ########## Create Right-Of-Way (ROW) featureclasses - query: LU == 4118
    ROW_outName = '{}ROW'.format(LU.split("LAND")[0])
    ROW_outPath = os.path.join(scratch_gdb_path, ROW_outName)
    
    if arcpy.Exists(ROW_outPath):
        print(ROW_outName, "already exists \n")
        
    else:
        start = time.time()
        print("start time:", time.ctime(start))
        print("Selecting ROW features from Land Use featureclass... \n saving to\n", ROW_outName)
        ROW_selection = arcpy.management.SelectLayerByAttribute(LU, "NEW_SELECTION", '"LU" = 4118')
        arcpy.management.CopyFeatures(ROW_selection, ROW_outPath)
        end = time.time()
        print("elapsed time:", (end-start)/60, "\n")
    
    
    #########  Create Residential (RES) Land Use featureclasses - query: LU <= 1190
    RES_outName = '{}RES'.format(LU.split("LAND")[0])
    RES_outPath = os.path.join(scratch_gdb_path, RES_outName)
    
    if arcpy.Exists(RES_outPath):
        print(RES_outName, "already exists \n")
        
    else:
        start = time.time()
        print("start time:", time.ctime(start))
        print("Selecting RES features from Land Use featureclass... \n saving to...", RES_outName)
        RES_selection = arcpy.management.SelectLayerByAttribute(LU, "NEW_SELECTION", '"LU" <= 1190')
        arcpy.management.CopyFeatures(RES_selection, RES_outPath)
        end = time.time()
        print("elapsed time:", (end-start)/60, "\n")
    #break


# In[6]:


'''  3. For each tiles Parcels FC, create two new FCs: Large Residential and Small Residential
            using one attribute query (Shape_Area </> 65000) and one location query (Parcels intersect RES FC)
                                    
                                    result = 24 new FC's
                                    
                                    NAMING SCHEME
                                    tile{}_LgResParcels
                                    tile{}_SmResParcels'''

arcpy.env.workspace = scratch_gdb_path

parcels_subsets = arcpy.ListFeatureClasses("tile*parcels")
RES_subsets = arcpy.ListFeatureClasses("tile*RES")

for parcels, RES in zip(parcels_subsets, RES_subsets):
        
        SMparcels_outName = '{}SmResParcels'.format(parcels.split("Parcels")[0])
        SMparcels_outPath = os.path.join(scratch_gdb_path, SMparcels_outName)
        LGparcels_outName = '{}LgResParcels'.format(parcels.split("Parcels")[0])
        LGparcels_outPath = os.path.join(scratch_gdb_path, LGparcels_outName)
        
        #this if-elif-else structure works ok, but could be edited to ensure both the SmResParcels and LgResParcels
        #exist for each tile... currently moves on if SmResParcels or LgResParcels exsists for a given tile
        if arcpy.Exists(SMparcels_outPath):
            print(SMparcels_outName, "\n already exists \n")
            
        elif arcpy.Exists(LGparcels_outPath):
            print(LGparcels_outName, "\n already exists \n")
        
        elif parcels.split("Parcels")[0] != RES.split("RES")[0]:
            print(parcels, "and", RES, "don't match up, troubleshoot the loop index \n")
        
        else:

            #############  Create Small Residential Parcels FC's #####################
            start = time.time()
            print("start time:", time.ctime(start), "\n Creating Small Residential Parcels")
            #Parcels that intersect with RES polys
            ParcelsRES_selection = arcpy.management.SelectLayerByLocation(parcels, 
                                                                             "INTERSECT", RES)

            #SMALLER than 65000 ft^2
            ParcelsRES_SM_selection = arcpy.management.SelectLayerByAttribute(ParcelsRES_selection, 
                                                                              "SUBSET_SELECTION", 
                                                                          '"Shape_Area" <= 65000')

            # If features matched criteria, write them to a new feature class
            matchcount = int(arcpy.GetCount_management(ParcelsRES_SM_selection)[0]) 

            if matchcount == 0:
                print('no features matched spatial and attribute criteria \n')
            else:                                                              
                print("saving", SMparcels_outName, "to scratch gdb")
                arcpy.CopyFeatures_management(ParcelsRES_SM_selection, SMparcels_outPath)
                end = time.time()
                print("elapsed time:", (end-start)/60, "minutes \n")
        

            ############## Create Large Residential Parcels FC's ######################
            start = time.time()
            print("start time:", time.ctime(start), "\n Creating Large Residential Parcels")
            #Parcels that intersect with RES polys
            ParcelsRES_selection = arcpy.management.SelectLayerByLocation(parcels, 
                                                                             "INTERSECT", RES)

            #LARGER than 65000 ft^2 but Smaller than 300,000 ft^2
            ParcelsRES_LG_selection = arcpy.management.SelectLayerByAttribute(ParcelsRES_selection, 
                                                                              "SUBSET_SELECTION",
                                                                              '"Shape_Area" >= 65000 AND "Shape_Area" <= 300000')
            # If features matched criteria, write them to a new feature class
            matchcount = int(arcpy.GetCount_management(ParcelsRES_LG_selection)[0]) 

            if matchcount == 0:
                print('no features matched spatial and attribute criteria \n')
            else: 
                print("saving", LGparcels_outName, "to scratch gdb")
                arcpy.CopyFeatures_management(ParcelsRES_LG_selection, LGparcels_outPath)
                end = time.time()
                print("elapsed time:", (end-start)/60, "minutes \n")   


# In[7]:


'''         4-5. Select Lg and Sm Res Parcels that intersect ROW featureclasses, buffer the result
                then union this with the orignal Sm and Lg Res Parcels and Dissolve them into one 
                    multipart feature
                                                
                                        new results (n=66) 
                                        **tile12 has no valid criteria
                                        NAMING SCHEME
                                        tile{}_SmResParcelsIntersectROW_buff4m
                                        tile{}_SmResParcelsIntersectROW_buff4m_Union
                                        tile{}_SmResParcelsIntersectROW_buff4m_UnionDissolve

                                        tile{}_LgResParcelsIntersectROW_buff4m
                                        tile{}_LgResParcelsIntersectROW_buff4m_Union
                                        tile{}_LgResParcelsIntersectROW_buff4m_UnionDissolve'''

arcpy.env.workspace = scratch_gdb_path

id_list = [1,2,3,5,6,7,8,9,10,11,12,13]
for ID in id_list:
    SmResParcel = "tile{}_SmResParcels".format(ID)
    LgResParcel = "tile{}_LgResParcels".format(ID)
    ROW = "tile{}_ROW".format(ID)
    
    SmBuff_outPath = os.path.join(scratch_gdb_path, SmResParcel + "IntersectROW_buff4m")
    SmBuffUnion_outPath = os.path.join(scratch_gdb_path, SmResParcel + "IntersectROW_buff4m_Union")
    SmBuffUnionDissolve_outPath = os.path.join(scratch_gdb_path, SmResParcel + "IntersectROW_buff4m_UnionDissolve")
    
    
    LgBuff_outPath = os.path.join(scratch_gdb_path, LgResParcel + "IntersectROW_buff4m")
    LgBuffUnion_outPath = os.path.join(scratch_gdb_path, LgResParcel + "IntersectROW_buff4m_Union")
    LgBuffUnionDissolve_outPath = os.path.join(scratch_gdb_path, LgResParcel + "IntersectROW_buff4m_UnionDissolve")
    
    ###### Small Residential Parcels #################################
    if not arcpy.Exists(os.path.join(scratch_gdb_path, SmResParcel)):
        print(SmResParcel, "doesn't exist, can't do rest of operations...\n")
    else: 
        #do the intersect then the buffer, save that, then do the union, and dissolve, save final AOI
        if arcpy.Exists(SmBuffUnionDissolve_outPath):
            print(SmBuff_outPath, "already exists \n")
        else:
            start = time.time()
            print("start time:", time.ctime(start), 
                  "\n Initiating", SmResParcel, "Intersect/Buff/Union/Dissolve...")
            Sm_intersect = arcpy.management.SelectLayerByLocation(SmResParcel, "INTERSECT", ROW)
            Sm_intersect_buff = arcpy.Buffer_analysis(Sm_intersect, SmBuff_outPath, "4 Meters", "FULL", 
                          "ROUND", "ALL")
            Sm_union = arcpy.Union_analysis([SmResParcel, Sm_intersect_buff], SmBuffUnion_outPath, "ONLY_FID")
            Sm_union_dissolve = arcpy.Dissolve_management(Sm_union, SmBuffUnionDissolve_outPath, "", "", 
                          "MULTI_PART")
            end = time.time()
            print("elapsed time:", (end-start)/60, "minutes \n")   
    ###### Large Residential Parcels #################################
    if not arcpy.Exists(os.path.join(scratch_gdb_path, LgResParcel)):
        print(LgResParcel, "doesn't exist, can't do rest of operations...\n")
    else: 
        #do the intersect then the buffer, save that, then do the union, and dissolve, save final AOI
        if arcpy.Exists(LgBuffUnionDissolve_outPath):
            print(LgBuff_outPath, "already exists \n")
        else:
            start = time.time()
            print("start time:", time.ctime(start), 
                  "\n Initiating", LgResParcel, "Intersect/Buff/Union/Dissolve...")
            Lg_intersect = arcpy.management.SelectLayerByLocation(LgResParcel, "INTERSECT", ROW)
            Lg_intersect_buff = arcpy.Buffer_analysis(Lg_intersect, LgBuff_outPath, "4 Meters", "FULL", 
                          "ROUND", "ALL")
            Lg_union = arcpy.Union_analysis([LgResParcel, Lg_intersect_buff], LgBuffUnion_outPath, "ONLY_FID")
            Lg_union_dissolve = arcpy.Dissolve_management(Lg_union, LgBuffUnionDissolve_outPath, "", "", 
                          "MULTI_PART")
            end = time.time()
            print("elapsed time:", (end-start)/60, "minutes \n")   
    #break


# In[10]:


'''6.  Extract impervious boolean raster from Sm and Lg Res Parcel AOI featureclass, apply different 
            smoothing filters to Sm and Lg parcel impervious raster extraction, then combine the two 
                Sm and Lg impervious raster products to one for each tile'''

imperv_raster_path = r'D:\EnviroAtlas\MULC_SanDiego\intermediate_data\FinalAttempt_ReclassSoilImperv\ImperviousThreshold_ras'

id_list = [1,2,3,5,6,7,8,9,10,11,12,13]
for ID in id_list:
    
    arcpy.env.workspace = scratch_gdb_path #so we can find the feature classes
    
    #passes over Sm and Lg final AOI fc's that don't exist (if Sm doesn't exist, assumes Lg doesn't either)
    #primarily needed to pass over tile 12 which correctly has been excluded by spatial and attribute queries
    #in prior code block
    if not arcpy.Exists("tile{}_SmResParcelsIntersectROW_buff4m_UnionDissolve".format(ID)):
        print("tile{}_SmResParcelsIntersectROW_buff4m_UnionDissolve".format(ID), "doesn't exist, passing...\n")
    
    elif not arcpy.Exists("tile{}_LgResParcelsIntersectROW_buff4m_UnionDissolve".format(ID)):
        print("tile{}_LgResParcelsIntersectROW_buff4m_UnionDissolve".format(ID), "doesn't exist, passing...\n")
    
    else:
        #identifing the inputs
        SmAOI = arcpy.management.MakeFeatureLayer("tile{}_SmResParcelsIntersectROW_buff4m_UnionDissolve".format(ID))
        LgAOI = arcpy.management.MakeFeatureLayer("tile{}_LgResParcelsIntersectROW_buff4m_UnionDissolve".format(ID))

        search_criteria = "tile{}_*.TIF".format(ID)
        q = os.path.join(imperv_raster_path, search_criteria)
        rasMask = glob.glob(q)
        ras = Raster(rasMask)
        
        #setting up outputs
        SmAOI_extract_outName = "tile{}_SmResParcelsAOI_impervExtractOver165.tif".format(ID)
        SmAOI_extract_outPath = os.path.join(final_dir, SmAOI_extract_outName)
        SmAOI_smoothed_extract_outName = "tile{}_SmResParcelsAOI_impervExtractOver165_smoothed.tif".format(ID)
        SmAOI_smoothed_extract_outPath = os.path.join(final_dir, SmAOI_smoothed_extract_outName)

        LgAOI_extract_outName = "tile{}_LgResParcelsAOI_impervExtractOver165.tif".format(ID)
        LgAOI_extract_outPath = os.path.join(final_dir, LgAOI_extract_outName)
        LgAOI_smoothed_extract_outName = "tile{}_LgResParcelsAOI_impervExtractOver165_smoothed.tif".format(ID)
        LgAOI_smoothed_extract_outPath = os.path.join(final_dir, LgAOI_smoothed_extract_outName)

        ######## Sm AOI Impervious Extract ###################################
        if arcpy.Exists(SmAOI_smoothed_extract_outPath):
            print(SmAOI_smoothed_extract_outName, "already exists \n")
        else:
            arcpy.env.workspace = r'in_memory' #to place the intermediate raster outputs in memory
            start = time.time()
            print("Start time: ", time.ctime(start), 
                  "\n Extracting impervious raster to ", "tile{}".format(ID), "SmAOI")
            SmAOI_extract = ExtractByMask(ras, SmAOI)
            SmNeighborhood = NbrRectangle(3, 3, "CELL") #neighborhood for filter
            SmAOI_smoothed_extract = FocalStatistics(SmAOI_extract, SmNeighborhood, "MAJORITY", "") #majority filter
            print("saving to: \n", SmAOI_smoothed_extract_outPath)
            SmAOI_smoothed_extract.save(SmAOI_smoothed_extract_outPath)
            end = time.time()
            print("elapsed time:", (end-start)/60, "minutes \n")
        ######## Lg AOI Impervious Extract ###################################
        if arcpy.Exists(LgAOI_smoothed_extract_outPath):
            print(LgAOI_smoothed_extract_outName, "already exists \n")
        else:
            arcpy.env.workspace = r'in_memory' #to place the intermediate raster outputs in memory
            start = time.time()
            print("Start time: ", time.ctime(start), 
                  "\n Extracting impervious raster to ", "tile{}".format(ID), "LgAOI")
            LgAOI_extract = ExtractByMask(ras, LgAOI)
            LgNeighborhood = NbrRectangle(5, 5, "CELL") #neighborhood for filter
            SmAOI_smoothed_extract = FocalStatistics(LgAOI_extract, LgNeighborhood, "MAJORITY", "") #majority filter
            print("saving to: \n", LgAOI_smoothed_extract_outPath)
            SmAOI_smoothed_extract.save(LgAOI_smoothed_extract_outPath)
            end = time.time()
            print("elapsed time:", (end-start)/60, "minutes \n")


# In[ ]:




