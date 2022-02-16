# IJ-Toolset: Aggregates and MTs

# User's request
The users has images presenting microtubules, nuclei and aggregates. The aim of the toolset is to isolate all three types of elements and characterize the morphometric parameters of the aggregate and evaluate their dependency to topological cues (distance to cell borders/MTs/nuclei). Input data are individual czi files, stored in a single folder.

![Example of input image](/illustrations/Example_image.jpg?raw=true)
**_Example of input image_**

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

![Example of output: distance maps](/illustrations/Distance_maps.jpg?raw=true)
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
12. The image of the calibrated distance map is saved in **output_folder/Distance_Maps/Basename-Cell_XXX_Nuclei-Map.tif**.

### Step 1.6: Generation of control images
For each tif file in the **output_folder/Cells**, the following operations are performed:
1. The image is opened.
2. The different detections ROIs are opened, colored and overlayed to the image as follows:
3. The Aggregates ROI is loaded from **output_folder/ROIs/Basename-Cell_XXX_Aggregates-Roi.roi** and colored in yellow.
4. The Cell ROI is loaded from **output_folder/ROIs/Basename-Cell_XXX_Cell-Roi.roi** and colored in magenta.
5. The MTs ROI is loaded from **output_folder/ROIs/Basename-Cell_XXX_MTs-Roi.roi** and colored in white.
6. The Nuclei ROI is loaded from **output_folder/ROIs/Basename-Cell_XXX_Nuclei-Roi.roi** and colored in cyan.
7. The image is flattened with all ROIs overlayed and saved in **output_folder/Controls/Basename-Cell_XXX_Control-Image.jpg**.
8. All ROIs are saved as a single file in **output_folder/Controls/Basename-Cell_XXX_Control-Rois.zip**.

![Example of output: control image](/illustrations/Segmentation.jpg?raw=true)
**_Example of output: control image_**

### Step 1.7: Data extraction
For each tif file in the **output_folder/Cells**, the following operations are performed:
1. The image is opened.
2. The three distances maps are loaded from **output_folder/Distance_Maps/**: **Basename-Cell_XXX_Cell-Map.tif**, **Basename-Cell_XXX_MTs-Map.tif** and **Basename-Cell_XXX_Nuclei-Map.tif**.
3. The aggregates ROI is loaded onto the first image from **output_folder/ROIs/Basename-Cell_XXX_Aggregates-Roi.roi**.
4. The composite ROI, made of individual aggregates, is splitted into individualized objects that are pushed into the ROI Manager.
5. In turn, each of the image is activated and the following measurements are performed within individual objects: 
    1. _Morphometry-related (on the original image):_ Area, Perimeter, Bounding-box, Ellipse fitting parameters, Feret's lengths and angle, Aspect ratio, Roundness, Circularity, Solidity, Circularity
    2. _Intensity-related (on the original image, on the aggregates channel):_ Mean, StdDev, Mode, Min, Max, Median
    3. _Topology-related (on the distance maps):_ Mean, StdDev, Mode, Min, Max, Median distance to MTs/cell/nucleus
6. Numerical values per aggregates are saved in **output_folder/Results/Basename-Cell_XXX.csv**.

## Tool 2: Randomize Aggregates
### Step 2.1: Generate randomized dataset
For each tif file in the **output_folder/Cells**, the following operations are performed:
1. The image is opened.
2. XY coordinates columns are extracted from the corresponding results table found in **output_folder/Results/Basename-Cell_XXX.csv**.
3. The cell and nuclei masks are opened from **output_folder/Masks/Basename-Cell_XXX_Cell-Mask.tif** and **output_folder/Masks/Basename-Cell_XXX_Nuclei-Mask.tif** respectively.
4. The nuclei mask is subtracted from the cell mask to create a mask for the cytoplasmic compartment: this defines the region where aggregates should be randomly placed.
5. For each randomization round:
    1. The original image is activated, duplicated and named "**Randomized**".
    2. On the duplicate, the aggregates channel is filled black.
    3. The cell and nuclei rois are opened from **output_folder/ROIs/Basename-Cell_XXX_Cell-ROI.roi** and **output_folder/ROIs/Basename-Cell_XXX_Nuclei-ROI.roi** respectively.
    4. Both ROIs are combined using a XOR operator: the resulting ROI is renamed and pushed to the ROI Manager as the Cytoplasm ROI, while both original ROIs are deleted from it.
    5. The ROI set containing the outlines of all aggregates is opened from output_folder/ROIs/Basename-Cell_XXX_Aggregates-RoiSet.zip and added to the ROI Manager.
    6. Only during the first round of randomization:
        1. The original image is selected and the aggregates channel is activated.
        2. All aggregates ROIs are combined into a single ROI.
        3. Pixels outside the ROI are set to black (pixels outside the aggregates area are considered to be part of the background).
        4. The cleaned, original image is saved as **output_folder/Random/ROIs/Basename-Cell_XXX_Original-Image.tif**.
        5. The current set of ROIs (aggregates and cytoplasm) is saved as **output_folder/Random/ROIs/Basename-Cell_XXX_Original-Rois.zip**.
    7. The first ROI (cytoplasm) is renamed "**Cytoplasm_wo_aggregates**".
    8. For each ROI, except the first one (ie for each aggregate ROI):
        1. The **Basename-Cell_XXX_Original-Image.tif** image is activated.
        2. The aggregate ROI is selected and its content is copied to the clipboard. 
        3. For each X and Y coordinates, a random draw is performed from a uniform distribution (intervalle: [0-image dimensions[).
        4. The **Randomized image** is activated.
        5. The aggregate ROI is selected and moved to match its newly calculated, randomized X, Y center.
        6. Basic parameters are retrieved ,such as the maximum intensity within the ROI. In case it isn't 0, this means that another aggregate has already been placed here: this randomization round is not valid.
        7. The **Cell-Mask** (mask of the cytoplam) image is activated.
        8. The aggregate ROI with its randomized X, Y center is recalled onto this image.
        9. Basic parameters are retrieved, such as the minimum intensity within the ROI. In case it isn't 255, this means that the aggregate is at least partially outside of the cytoplasm: this randomization round is not valid.
        10. Validity of the randomized coordinated is check: if invalid, a new set is generated and tested. If validated, the workflow goes on.
        11. The **Randomized** image is activated.
        12. The aggregate ROI with its randomized X, Y center is recalled onto this image.
        13. The content of the aggregate ROI, copied from the **Basename-Cell_XXX_Original-Image.tif** image is pasted onto the newly moved ROI.
        14. The ROI Manager is updated so that the new position of the aggregate ROI is taken into account.
        15. From the ROI Manager, both the newly placed aggregate and the Cytoplasm_wo_aggregates are selected, then combined using a XOR operator: the aggregate region is excluded from the cytoplasmic region and updated in the ROI Manager.
6. Original and randomized X, Y coordinates are logged into a results table, then saved as **output_folder/Random/Results/Basename-Cell_XXX-Round_(Original or Randomized)-Image.csv**.
7. The content of the ROI Manager is saved as **output_folder/Random/ROIs/Basename-Cell_XXX-Round_(Original or Randomized)-Rois.zip**.
8. The randomized image is saved as **output_folder/Random/Cells/Basename-Cell_XXX-Round_Randomized-Image.tif**.

![Example of output: randomized image](/illustrations/Example_randomization.jpg?raw=true)
**_Example of output: randomized image_**

### Step 2.2: Data extraction

 
