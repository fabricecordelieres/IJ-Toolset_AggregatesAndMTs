# IJ-Toolset_AggregateAndMTs

# User's request
The users has images presenting microtubules, nuclei and aggregates. The aim of the toolset is to isolate all three types of elements and characterize the morphometric parameters of the aggregate and evaluate their dependency to topological cues (distance to cell borders/MTs/nuclei).

# What does it do ?
The workflow comes as a toolset made of 2 tools and includes a Python script to quickly review the data.

## Tool 1: Analyze data
This tool aims at segmenting the original image and performing morphological and topological data extraction. It performs in 7 steps:

### Step 1.1: Cell detection
For each czi file in the **input_folder**, the following operations are performed:
1. The image is opened.
2. Cells are segmented as follows:
    1. The original image is duplicated.
    2. The image is converted to 32-bits.
    3. For each channel, basic statistics are extracted, the average intensity is subtracted, the resulting image is divided by the image's standard deviation. This assumes the histogram to follow a gaussian distribution and allows normalizing all intensities (new mean is 0 and standard deviation 1).
    4. The image is converted to 16-bits.
   5. For each image, the histogram is equalized normalized and saturated up to 10% of the pixels.
    6. Low intensities are enhanced using a gamma transform (value: 0.45).
    7. All channels are blurred using a Gaussian filter (sigma: 10).
    8. 8. A z projection is generated from all channels but the first (DAPI) using a median rule.
    9. The image is thresholded using the Yen method, then converted to a mask.
    10 Cells candidates are separated on the mask using a Watershed process.
    11. Individual cells' outlines are retrieved using the "Analyze Particles" function, and ROIs pushed to the ROI Manager. Cells which area lay below 25000 pixels are excluded.
3. All ROIs are displayed on the original image.
4. The user is invited to modify/add/remove rois: any modification is possible, the only import part is that at the end of the step the ROI Manager is not empty.
5. All ROIs are renamed in the form **"Cell_XXX"**.
6. The content of the ROI Manager is saved in the **output_folder/ROIs/Basename.zip**.

### Step 1.2: Cut out individual cells
For each czi file in the **input_folder**, the following operations are performed:
1. The image is opened.
2. The cell ROIs are loaded.
3. For each ROI:
    1. The part of image containing the cell is duplicated.
    2. The content of the image outside the ROI is set to black.
    3. The resulting image is saved in **output_folder/Cells/Basename-Cell_XXX.tif**.
    4. The individual cell ROI is saved in **output_folder/ROIs/Basename-Cell_XXX_Cell-Roi.roi**.
    5. The image is converted to a mask and saved in **output_folder/Masks/Basename-Cell_XXX_Cell-Mask.tif**.
    6. From the mask a distance map is computed: each pixel now carries as an intensity its distance to the closest background pixel, expressed in pixels.
    7. The image is converted to 32-bits.
    8. The selection is inverted to encompass only pixels outside the cell: all pixels there are set to NaN (Not a Number: to be used as a marker for background).
    9. The image is multiplied by the pixel distance calibration: the distance map now expresses the distances in microns, not in pixels anymore.
    10. The image of the calibrated distance map is saved in **output_folder/Distance_Maps/Basename-Cell_XXX_Cell-Map.tif**.

[Example of output: distance maps](https://github.com/fabricecordelieres/IJ-Toolset_AggregateAndMTs/blob/main/illustrations/Distance_maps.jpg?raw=true)
**_Example of output: distance maps_**

### Step 1.3: MTs segmentation
For each tif file in the **output_folder/Cells**, the following operations are performed:
1. The image is opened and the MTs' channel is duplicated.
2. The cell ROI is loaded from **output_folder/ROIs/Basename-Cell_XXX_Cell-Roi.roi**.
3. Background is subtracted using the rolling-ball algorithm (radius: 2 pixels).
4. The image is thresholded using the Triangle algorithm, then converted to a mask.
5. The mask is further processed using a single iteration of morphological opening (count: 5).
6. The corresponding outlines are saved as single ROI in **output_folder/ROIs/Basename-Cell_XXX_MTs-Roi.roi**.
7. The mask is saved in **output_folder/Masks/Basename-Cell_XXX_MTs-Mask.tif**.
8. From the mask a distance map is computed: each pixel now carries as an intensity its distance to the closest background pixel, expressed in pixels.
9. The image is converted to 32-bits.
10. The selection is inverted to encompass only pixels outside the cell: all pixels there are set to NaN (Not a Number: to be used as a marker for background).
11. The image is multiplied by the pixel distance calibration: the distance map now expresses the distances in microns, not in pixels anymore.
12. The image of the calibrated distance map is saved in **output_folder/Distance_Maps/Basename-Cell_XXX_MTs-Map.tif**.

### Step 1.4: Aggregates segmentation
For each tif file in the **output_folder/Cells**, the following operations are performed:
1. The image is opened and the aggregates' channel is duplicated twice.
2. The cell ROI is loaded from **output_folder/ROIs/Basename-Cell_XXX_Cell-Roi.roi**.
3. On the duplicates, a Gaussian blur is applied of radii 8 and 1 pixels.
4. The first duplicate is subtracted to the second: this operation, called Difference of Gaussian (DoG) allows extracting rather round objects within the 1-8 pixels range in diameter.
5. A gamma transform is applied to the DoG to enhance low intensities (value: 0.5)
6. The image is thresholded using the Yen algorithm, then converted to a mask.
7. The mask is subjected to a watershed transform.
8. The corresponding outlines are saved as single ROI in **output_folder/ROIs/Basename-Cell_XXX_Aggregates-Roi.roi**.
9. The mask is saved in **output_folder/Masks/Basename-Cell_XXX_Aggregates-Mask.tif**.

### Step 1.5: Nuclei segmentation
For each tif file in the **output_folder/Cells**, the following operations are performed:
1. The image is opened and the nucleus' channel is duplicated.
2. The cell ROI is loaded from **output_folder/ROIs/Basename-Cell_XXX_Cell-Roi.roi**.
3. The duplicate is subjected to median filtering (radius: 5).
4. The image is thresholded using the Li algorithm, then converted to a mask.
5. The corresponding outlines are saved as single ROI in **output_folder/ROIs/Basename-Cell_XXX_Nuclei-Roi.roi**.
6. The mask is saved in **output_folder/Masks/Basename-Cell_XXX_Nuclei-Mask.tif**.
7. The mask is inverted to build a distance map FROM the nucleus (not within the nucleus).
8. From the mask a distance map is computed: each pixel now carries as an intensity its distance to the closest background pixel, expressed in pixels.
9. The image is converted to 32-bits.
10. The selection is inverted to encompass only pixels outside the cell: all pixels there are set to NaN (Not a Number: to be used as a marker for background).
11. The image is multiplied by the pixel distance calibration: the distance map now expresses the distances in microns, not in pixels anymore.
12. The image of the calibrated distance map is saved in **output_folder/Distance_Maps/Basename-Cell_XXX_MTs-Map.tif**.

### Step 1.1: Generation of control images
### Step 1.1: Data extraction
## Tool 2: Randomize Aggregates
## Python script: Quickly review the data



 
