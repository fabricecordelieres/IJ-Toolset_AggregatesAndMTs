//Parameters for channels
DAPI=1;
MTs=2;
aggregates=3;

//Parameters for cells detection
gammaCells=0.45;
nItCloseCells=0; //5;
nItDilateCells=0; //5;
minSizeCells=25000;

//Parameters for nuclei detection
medRadNuclei=5;
minSizeNuclei=250;

//Parameters for MTs detection
subBkgdRadMTs=2;

//Parameters for aggregates detection
gaussMinAggregates=1;
gaussMaxAggregates=8;
gammaAggregates=0.5
	


//*********************************************************************************
macro "Analyze data Action Tool - C0f0D07D09D17D19D25D29D35D39D3aD3cD3dD46D48D49D58D5cD5dD5eD5fD62D63D6bD71D73D7cD7eD7fD89D91D92D93D98D9aD9bD9cD9dDa1Da5Da9Db7DbaDbbDc4Dc7Dd8Dd9De3C050D16D18D1aD26D27D28D2aD2cD37D38D3bD3eD44D45D47D4aD4bD4cD4eD53D54D59D5aD69D6aD6cD6dD6eD79D7aD7bD81D82D83D8bD8cD8dD94D99Da0Da3Da6Da7Da8DaaDacDadDb1Db2Db3Db4Db5Db8Db9DbcDc1Dc2Dc3Dc5Dc6Dc9DcaDcbDd1Dd2Dd4Dd5Dd6Dd7DdaDe2De4De5De6De7De8Df3Cff0D36D72D7dD8aD90Da2Dc8Dd3Df4Cf50D06D08D2bD4dD5bD6fDa4DabDb6C05fD55D56D57D64D65D66D67D68D74D75D76D77D78D84D85D86D87D88D95D96D97"{
	//Parameters for channels
	DAPI=1;
	MTs=2;
	aggregates=3;
	
	//Parameters for cells detection
	gammaCells=0.45;
	sigmaCells=10;
	nItCloseCells=0; //5;
	nItDilateCells=0; //5;
	minSizeCells=25000;
	
	//Parameters for nuclei detection
	medRadNuclei=5;
	minSizeNuclei=250;
	
	//Parameters for MTs detection
	subBkgdRadMTs=2;
	
	//Parameters for aggregates detection
	gaussMinAggregates=1;
	gaussMaxAggregates=8;
	gammaAggregates=0.5
	
	
	
	in=getDir("Where are the images ?");
	out=getDir("Where to save data ?");

	run("Close All");
	
	prepareData(in, out, DAPI, aggregates, gammaCells, sigmaCells, minSizeCells);
	
	setBatchMode(true);
	cutCells(in, out);
	isolateMTs(out, MTs, subBkgdRadMTs);
	isolateAggregates(out, aggregates, gaussMinAggregates, gaussMaxAggregates, gammaAggregates);
	isolateNuclei(out, DAPI, medRadNuclei, minSizeNuclei);

	generateControlData(out);
	
	analyze(out);
	setBatchMode("exit and display");
}
//*********************************************************************************


//*********************************************************************************
macro "Randomize Aggregates Action Tool - C333D12D13D1bD22D23D29D2cD32D33D39D48D51D57D61D64D67D71D7eD82D85D86D87D88D89D8aD8bD8cD8dD8eD91D9eDa1Da4Db7Db8DbdDc9Dd2Dd3Dd9DdcDe2De3CdddD02D0cD21D28D2bD2dD34D37D3bD47D52D53D59D60D62D63D65D73D76D78D79D7aD7bD7cD7dD90D93D96D97D98D99D9aD9bD9cD9dD9fDa0Da2Da3Da5Da9Db6Db9DbcDbeDc4Dc7DcaDd1Dd4DdaDdbDddDfcC999D03D04D05D06D07D08D09D0aD0bD1cD2aD31D38D3aD3dD41D42D43D44D49D4cD56D58D5eD66D68D6dD70D72D75D77D7fD80D83D84D8fD92D95Da7Da8DadDaeDb1Db2Db3Db4Dc1Dc8DccDcdDd8De4De5De6De7De8De9DeaDecDf2DfbC666D14D15D16D17D18D19D1aD3cD4dD54D5dD6eD74D81D94Dc2Dc3DebDf3Df4Df5Df6Df7Df8Df9Dfa"{
	//Parameters for channels
	DAPI=1;
	MTs=2;
	aggregates=3;
	
	out=getDir("Where were the data saved ?");
	nRandRounds=getNumber("Number of randomization rounds per image", 3);

	run("Close All");

	cellsPath=out+"Cells"+File.separator;
	
	setBatchMode(true);
	
	files=getFileList(cellsPath);
	for(i=0; i<files.length; i++){
		basename=replace(files[i], ".tif", "");
		randomizeData(out, basename, aggregates, nRandRounds);
	}
	
	analyzeRandomizedDataset(out, aggregates);
	setBatchMode("exit and display");
}
//*********************************************************************************










	
//------------------------------------------------------------------------------------
function prepareData(in, out, dapiCh, aggregatesCh, gamma, sigma, minSize){	
	roisPath=out+"ROIs"+File.separator;

	tmp=File.makeDirectory(roisPath);
	
	files=getFileList(in);

	for(i=0; i<files.length; i++){
		if(endsWith(files[i], ".czi")){
			run("Bio-Formats Importer", "open=["+in+files[i]+"] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
			
			basename=replace(replace(getTitle(), ".czi", ""), ".tif", "");
			ori=getTitle();
	
			setBatchMode(true);
			segmentCells(DAPI, gamma, sigma, minSize);
			selectWindow(ori);
			roiManager("UseNames", "true");
			roiManager("Show All with labels");
			setBatchMode("exit and display");

			Stack.setChannel(aggregatesCh);
			run("Enhance Contrast", "saturated=5");
			Stack.setDisplayMode("grayscale");
			setTool("freehand");
			
			waitForUser("Check that all cells are detected", "Add missing cells (draw then add using t key)\nRemove mis-detected cells (del)\nThen press Ok");

			resetMinAndMax;
			Stack.setDisplayMode("composite");
			
			renameRois("Cell", 0, roiManager("Count"), "red");
			roiManager("Deselect");
			roiManager("Remove Channel Info");
			roiManager("Remove Slice Info");
			roiManager("Remove Frame Info");

			roiManager("Save", roisPath+basename+".zip");

			run("Close All");
		}
	}
}

//------------------------------------------------------------------------------------
function segmentCells(dapiCh, gamma, sigma, minSize){
	roiManager("Reset");
	run("Select None");

	ori=getTitle();

	run("Duplicate...", "title=tmpCells duplicate");

	getDimensions(width, height, channels, slices, frames);
	run("32-bit");
	for(i=1; i<=channels; i++){
		Stack.setChannel(i);
		getRawStatistics(nPixels, mean, min, max, std, histogram);
		run("Subtract...", "value="+mean+" slice");
		run("Divide...", "value="+std+" slice");
		resetMinAndMax();
	}
	run("Hyperstack to Stack");

	run("16-bit");
	run("Enhance Contrast...", "saturated=10 normalize equalize process_all");
	run("Gamma...", "value="+gamma);
	run("Gaussian Blur...", "sigma="+sigma+" stack");
	
	
	run("Z Project...", "start=2 projection=[Median]");
	
	setAutoThreshold("Yen dark");
	run("Convert to Mask");
	run("Watershed");
	
	run("Analyze Particles...", "size="+minSize+"-Infinity pixel show=Nothing exclude add");
	
	renameRois("Cell", 0, roiManager("Count"), "Red");
	
	close("*tmp*");
	selectWindow(ori);
}

//------------------------------------------------------------------------------------
function cutCells(in, out){
	cellsPath=out+"Cells"+File.separator;
	cellsMapsPath=out+"Distance_Maps"+File.separator;
	roisPath=out+"ROIs"+File.separator;
	cellsMasksPath=out+"Masks"+File.separator;
	
	tmp=File.makeDirectory(cellsPath);
	tmp=File.makeDirectory(cellsMapsPath);
	tmp=File.makeDirectory(roisPath);
	tmp=File.makeDirectory(cellsMasksPath);

	
	img=getFileList(in);
	
	for(i=0; i<img.length; i++){
		if(endsWith(img[i], ".czi")){
			run("Bio-Formats Importer", "open=["+in+img[i]+"] autoscale color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
			basename=replace(replace(getTitle(), ".czi", ""), ".tif", "");
			ori=getTitle();
			
			roiManager("Reset");
			if(File.exists(roisPath+basename+".zip")){
				roiManager("Open", roisPath+basename+".zip");
			}else if(File.exists(roisPath+basename+".roi")){
				roiManager("Open", roisPath+basename+".roi");
			}
			
			for(j=0; j<roiManager("Count"); j++){
				selectWindow(ori);
				roiManager("Select", j);
				roiName=Roi.getName;
				run("Duplicate...", "duplicate");
				setBackgroundColor(0, 0, 0);
				run("Clear Outside");
				run("Select None");
				run("Remove Overlay");
				saveAs("Tiff", cellsPath+basename+"-"+roiName+".tif");

				run("Restore Selection");
				run("Create Mask");
				saveAs("Tiff", cellsMasksPath+basename+"-"+roiName+"_Cell-Mask.tif");
				run("Distance Map");
				run("Restore Selection");
				saveAs("Selection", roisPath+basename+"-"+roiName+"_Cell-Roi.roi");
				run("Make Inverse");
				run("32-bit");
				run("Add...", "value="+NaN);
				getPixelSize(unit, pixelWidth, pixelHeight);
				run("Select None");
				run("Multiply...", "value="+pixelWidth);
				run("Rainbow RGB");
				run("Remove Overlay");
				saveAs("Tiff", cellsMapsPath+basename+"-"+roiName+"_Cell-Map.tif");
		
				selectWindow(ori);
				close("\\Others");
			}
			run("Close All");
		}
	}
}

//------------------------------------------------------------------------------------
function isolateMTs(out, MTsCh, subBkgdRad){
	cellsPath=out+"Cells"+File.separator;
	roisPath=out+"ROIs"+File.separator;
	mapsPath=out+"Distance_Maps"+File.separator;
	masksPath=out+"Masks"+File.separator;
	
	tmp=File.makeDirectory(mapsPath);
	tmp=File.makeDirectory(roisPath);
	tmp=File.makeDirectory(masksPath);

	img=getFileList(cellsPath);
	
	for(i=0; i<img.length; i++){
		open(cellsPath+img[i]);
		basename=replace(img[i], ".tif", "");

		run("Duplicate...", "title=MTs_distMap duplicate channels="+MTsCh);
		resetMinAndMax();

		//Retrieve the cell
		open(roisPath+basename+"_Cell-Roi.roi");
		
		run("Subtract Background...", "rolling="+subBkgdRad);
		setAutoThreshold("Triangle dark");
		run("Convert to Mask");
		run("Options...", "iterations=1 count=5 pad do=Open");
		run("Create Selection");
		saveAs("Selection", roisPath+basename+"_MTs-Roi.roi");
		run("Select None");
		run("Remove Overlay");
		saveAs("Tiff", masksPath+basename+"_MTs-Mask.tif");
		run("Invert");
		run("Distance Map");
		selectWindow(img[i]);
		selectWindow(basename+"_MTs-Mask.tif");
		open(roisPath+basename+"_Cell-Roi.roi");
		run("Make Inverse");
		run("32-bit");
		run("Add...", "value="+NaN);
		
		getPixelSize(unit, pixelWidth, pixelHeight);
		run("Select None");
		run("Multiply...", "value="+pixelWidth);
		run("Rainbow RGB");
		run("Remove Overlay");
		
		saveAs("Tiff", mapsPath+basename+"_MTs-Map.tif");
		
		run("Close All");
	}
}

//------------------------------------------------------------------------------------
//Isolate aggregates
function isolateAggregates(out, aggregatesCh, gaussMin, gaussMax, gamma){
	cellsPath=out+"Cells"+File.separator;
	roisPath=out+"ROIs"+File.separator;
	masksPath=out+"Masks"+File.separator;
	
	tmp=File.makeDirectory(roisPath);
	tmp=File.makeDirectory(masksPath);

	img=getFileList(cellsPath);
	
	for(i=0; i<img.length; i++){
		open(cellsPath+img[i]);
		basename=replace(img[i], ".tif", "");

		run("Duplicate...", "title=Aggregates_mask duplicate channels="+aggregatesCh);
		resetMinAndMax();

		//Retrieve the cell
		open(roisPath+basename+"_Cell-Roi.roi");

		run("Select None");
		run("Duplicate...", "title=Spots duplicate channels="+aggregatesCh);
		run("Duplicate...", "title=Spots_Gauss duplicate");
		run("Gaussian Blur...", "sigma="+gaussMax);
		selectWindow("Spots");
		run("Gaussian Blur...", "sigma="+gaussMin);
		imageCalculator("Subtract create", "Spots", "Spots_Gauss");
		rename("DoG");
		run("Gamma...", "value="+gamma);
		close("Spots*");
		setAutoThreshold("Yen dark");
		run("Convert to Mask");
		run("Watershed");
		
		run("Create Selection");
		saveAs("Selection", roisPath+basename+"_Aggregates-Roi.roi");
		run("Select None");
		saveAs("Tiff", masksPath+basename+"_Aggregates-Mask.tif");
		run("Close All");
	}
}


//------------------------------------------------------------------------------------
//Supposes that cells have been added to the ROI Manager
function isolateNuclei(out, dapiCh, medRad, minSize){
	cellsPath=out+"Cells"+File.separator;
	roisPath=out+"ROIs"+File.separator;
	masksPath=out+"Masks"+File.separator;
	mapsPath=out+"Distance_Maps"+File.separator;
	
	tmp=File.makeDirectory(roisPath);
	tmp=File.makeDirectory(masksPath);
	tmp=File.makeDirectory(mapsPath);

	img=getFileList(cellsPath);
	
	for(i=0; i<img.length; i++){
		open(cellsPath+img[i]);
		basename=replace(img[i], ".tif", "");
		run("Duplicate...", "title=Mask_Nuclei duplicate channels="+dapiCh);
		
		//Retrieve the cell
		open(roisPath+basename+"_Cell-Roi.roi");

		/*Old version
		run("Median...", "radius="+medRad);
		setAutoThreshold("Triangle dark");
		run("Convert to Mask");
		run("Watershed");
		*/
		run("Median...", "radius="+medRad);
		setAutoThreshold("Li dark");
		run("Convert to Mask");
		run("Create Selection");
		saveAs("Selection", roisPath+basename+"_Nuclei-Roi.roi");

		run("Select None");
		run("Remove Overlay");
		saveAs("Tiff", masksPath+basename+"_Nuclei-Mask.tif");

		run("Invert");
		run("Distance Map");

		selectWindow(img[i]);
		selectWindow(basename+"_Nuclei-Mask.tif");
		open(roisPath+basename+"_Cell-Roi.roi");
		run("Make Inverse");
		run("32-bit");
		run("Add...", "value="+NaN);
		
		getPixelSize(unit, pixelWidth, pixelHeight);
		run("Select None");
		run("Multiply...", "value="+pixelWidth);
		run("Rainbow RGB");
		run("Remove Overlay");
		
		saveAs("Tiff", mapsPath+basename+"_Nuclei-Map.tif");
		run("Close All");
	}
}

//------------------------------------------------------------------------------------
function generateControlData(out){
	cellsPath=out+"Cells"+File.separator;
	cellsMapsPath=out+"Distance_Maps"+File.separator;
	roisPath=out+"ROIs"+File.separator;
	controlPath=out+"Controls"+File.separator;
	
	tmp=File.makeDirectory(controlPath);
	
	
	rois=newArray("Aggregates", "Cell", "MTs", "Nuclei");
	colors=newArray("yellow", "magenta", "white", "cyan");


	files=getFileList(cellsPath);

	for(i=0; i<files.length; i++){
		if(endsWith(files[i], ".tif")){
			roiManager("Reset");
			run("Close All");
			
			open(cellsPath+files[i]);
			basename=replace(files[i], ".tif", "");
			run("Flatten");
			
			for(j=0; j<rois.length; j++){
				open(roisPath+basename+"_"+rois[j]+"-Roi.roi");
				Roi.setStrokeColor(colors[j]);
				Roi.setName(rois[j]);
				roiManager("Add");
			}
			roiManager("Show All without labels");
			run("Flatten");
			saveAs("Jpeg", controlPath+basename+"_Control-Image.jpg");
			roiManager("Save", controlPath+basename+"_Control-Rois.zip");
			
			run("Close All");
			roiManager("Reset");
		}
	}
}

//------------------------------------------------------------------------------------
function analyze(out){
	cellsPath=out+"Cells"+File.separator;
	roisPath=out+"Rois"+File.separator;
	mapsPath=out+"Distance_Maps"+File.separator;
	resultsPath=out+"Results"+File.separator;

	suffixes=newArray("Cell", "MTs", "Nuclei");
	
	tmp=File.makeDirectory(resultsPath);

	img=getFileList(cellsPath);

	for(i=0; i<img.length; i++){
		basename=replace(img[i], ".tif", "");

		open(cellsPath+img[i]);
		roiManager("Reset");
		open(roisPath+basename+"_Aggregates-Roi.roi");
		roiManager("Split");
		renameRois("Aggregate", 0, roiManager("Count"), "green");
		roiManager("Save", roisPath+basename+"_Aggregates-RoiSet.zip");

		run("Clear Results");
		run("Set Measurements...", "area mean standard min modal centroid perimeter bounding fit shape feret's median display redirect=None decimal=4");
		roiManager("Measure");
		Table.rename("Results", "Data");
		close();
		
		for(j=0; j<suffixes.length; j++){
			open(mapsPath+basename+"_"+suffixes[j]+"-Map.tif");

			getPixelSize(unit, pixelWidth, pixelHeight);
			//mesure mindistance to object
			run("Set Measurements...", "mean standard modal min median redirect=None decimal=4");
			//push to results table
			roiManager("Measure");

			headings=split(Table.headings, "\t");

			for(k=1; k<headings.length; k++){ //Skips the first heading: Index
				selectWindow("Results");
				col=Table.getColumn(headings[k]);
				selectWindow("Data");
				Table.setColumn(headings[k]+"_distance_to_"+suffixes[j]+"_in_"+unit, col);
			}
			selectWindow("Results");
			run("Close");
			selectWindow("Data");
		}
		Table.save(resultsPath+basename+".csv");
		run("Close");
		run("Close All");
	}
	
}

//------------------------------------------------------------------------------------
function randomizeData(out, basename, aggregatesCh, nRandRounds){
	cellsPath=out+"Cells"+File.separator;
	roisPath=out+"ROIs"+File.separator;
	masksPath=out+"Masks"+File.separator;
	resultsPath=out+"Results"+File.separator;
	randomPath=out+"Random"+File.separator;
	randomCellsPath=out+"Random"+File.separator+"Cells"+File.separator;
	randomRoisPath=out+"Random"+File.separator+"ROIs"+File.separator;
	randomCoordsPath=out+"Random"+File.separator+"Coords"+File.separator;
	
	tmp=File.makeDirectory(randomPath);
	tmp=File.makeDirectory(randomCellsPath);
	tmp=File.makeDirectory(randomRoisPath);
	tmp=File.makeDirectory(randomCoordsPath);
	
	open(resultsPath+basename+".csv");
	xOri=Table.getColumn("X");
	yOri=Table.getColumn("Y");
	selectWindow(basename+".csv");
	run("Close");
	
	open(cellsPath+basename+".tif");
	getDimensions(width, height, channels, slices, frames);
	getPixelSize(unit, pixelWidth, pixelHeight);
	Stack.setChannel(aggregatesCh);
	run("Select None");

	open(masksPath+basename+"_Cell-Mask.tif");
	rename("Cell-Mask");
	open(masksPath+basename+"_Nuclei-Mask.tif");
	rename("Nuclei-Mask");
	imageCalculator("Subtract create", "Cell-Mask","Nuclei-Mask");
	rename("Cell_Mask");
	close("*-Mask");
		
	
	for(j=0; j<nRandRounds; j++){
		selectWindow(basename+".tif");
		run("Select None");
		run("Duplicate...", "title=Randomized duplicate");
		Stack.setChannel(aggregatesCh);
		run("Select All");
		setForegroundColor(0, 0, 0);
		run("Fill", "slice");
		
		roiManager("Reset");
		roiManager("Show None");
		roiManager("Open", roisPath+basename+"_Cell-Roi.roi");
		roiManager("Open", roisPath+basename+"_Nuclei-Roi.roi");
		
		roiManager("Select", newArray(0,1));
		roiManager("XOR");
		roiManager("Add");
		roiManager("Select", 2);
		roiManager("Rename", "Cytoplasm");
		roiManager("Select", newArray(0,1));
		roiManager("Delete");
		
		xRand=newArray(xOri.length);
		yRand=newArray(yOri.length);
		
		roiManager("Open", roisPath+basename+"_Aggregates-RoiSet.zip");
		
		//Clean the original image's aggregates background
		if(j==0){
			rois=Array.getSequence(roiManager("Count")-1);
			rois=Array.slice(rois,1,rois.length-1);
			selectWindow(basename+".tif");
			roiManager("Select", rois);
			roiManager("Remove Channel Info");
			roiManager("Remove Slice Info");
			roiManager("Remove Frame Info");
			roiManager("Combine");
			setForegroundColor(0, 0, 0);
			Stack.setChannel(aggregatesCh);
			run("Clear Outside", "slice");
			run("Select None");
			saveAs("Tiff", randomCellsPath+basename+"_Original-Image.tif");
			rename(basename+".tif");
			roiManager("Save", randomRoisPath+basename+"_Original-Rois.zip");
		}
		
		
		roiManager("Select", 0);
		Roi.setName("Cytoplasm_wo_aggregates");
		roiManager("Add");
		
		setBatchMode(true);
		
		nRois=roiManager("Count")-1;
		
		for(i=0; i<nRois-1; i++){
			xRand[i]=-1;
			yRand[i]=-1;
		
			selectWindow(basename+".tif");
			roiManager("Select", i+1);
			run("Copy");
			getBoundingRect(xBB, yBB, widthBB, heightBB);
			selectWindow("Randomized");
		
			roiManager("Select", roiManager("Count")-1);

			isRoiInCyto=false;
			
			//while(!Roi.contains(xRand[i]-widthBB/2, yRand[i]-heightBB/2) || !Roi.contains(xRand[i]+widthBB/2, yRand[i]+heightBB/2)){
			while(!isRoiInCyto){
				//Check for point in region
				xRand[i]=width*random;
				yRand[i]=height*random;
		
				//Check for overlap
				selectWindow("Randomized");
				roiManager("Select", i+1);
				getBoundingRect(xBB, yBB, widthBB, heightBB);
				Roi.move(xRand[i]-widthBB/2, yRand[i]-heightBB/2);
				getStatistics(area, mean, min, max, std, histogram);

				selectWindow("Cell_Mask");
				run("Restore Selection");
				getStatistics(areaMask, meanMask, minMask, maxMask, stdMask, histogramMask);

				isRoiInCyto=true;
				if(max!=0 || minMask!=255){
					isRoiInCyto=false;
				}
			}
		
			roiManager("Select", i+1);
			getBoundingRect(xBB, yBB, widthBB, heightBB);
			Roi.move(xRand[i]-widthBB/2, yRand[i]-heightBB/2);
			run("Paste");
			roiManager("Update");
		
			roiManager("Select", newArray(i+1, roiManager("Count")-1));
			roiManager("XOR");
			Roi.setName("Cytoplasm_wo_aggregates");
			roiManager("Add");
		}
		setBatchMode("exit and display");
		
		//Remove all but the last added Rois
		rois=Array.getSequence(roiManager("Count"));
		rois=Array.slice(rois,nRois,rois.length-1);
		roiManager("Select", rois);
		roiManager("Delete");
		
		Table.create("Randomized_coordinates");
		Table.setColumn("X_original", xOri);
		Table.applyMacro("X_original=X_original/"+pixelWidth);
		Table.setColumn("Y_original", yOri);
		Table.applyMacro("Y_original=Y_original/"+pixelHeight);
		Table.setColumn("X_randomized", xRand);
		Table.setColumn("Y_randomized", yRand);
		Table.save(randomCoordsPath+basename+"-"+(j+1)+"_Randomized-coordinates.csv");
		run("Close");
		
		roiManager("Save", randomRoisPath+basename+"-"+(j+1)+"_Randomized-Rois.zip");
		selectWindow("Randomized");
		run("Select None");
		saveAs("Tiff", randomCellsPath+basename+"-"+(j+1)+"_Randomized-Image.tif");
		close();
	}
	run("Close All");
}

//------------------------------------------------------------------------------------
function analyzeRandomizedDataset(out, aggregatesCh){
	cellsPath=out+"Cells"+File.separator;
	roisPath=out+"ROIs"+File.separator;
	mapsPath=out+"Distance_Maps"+File.separator;
	randomPath=out+"Random"+File.separator;
	randomCellsPath=randomPath+"Cells"+File.separator;
	randomRoisPath=randomPath+"ROIs"+File.separator;
	randomCoordsPath=randomPath+"Coords"+File.separator;
	randomResultsPath=randomPath+"Results"+File.separator;
	
	tmp=File.makeDirectory(randomResultsPath);


	files=getFileList(randomCellsPath);

	for(i=0; i<files.length; i++){
		run("Close All");
		
		basename=replace(files[i], ".tif", "");
		oriName=substring(basename, 0, lastIndexOf(basename, "_"));
		if(indexOf(basename, "Original")==-1) oriName=substring(oriName, 0, lastIndexOf(oriName, "-"));

		roiManager("Reset");
		roiManager("Open", randomRoisPath+replace(basename, "Image", "Rois")+".zip");
		open(randomCellsPath+files[i]);
		Stack.setChannel(aggregatesCh);
		removeCytoplasmRois();
		run("Clear Results");
		run("Set Measurements...", "area mean standard min modal centroid perimeter bounding fit shape feret's median display redirect=None decimal=4");
		roiManager("Measure");
		Table.rename("Results", "Data");
		close();
		
		suffixes=newArray("Cell", "MTs", "Nuclei");
		
		for(j=0; j<suffixes.length; j++){
			open(mapsPath+oriName+"_"+suffixes[j]+"-Map.tif");
			getPixelSize(unit, pixelWidth, pixelHeight);

			//mesure mindistance to object
			run("Set Measurements...", "mean standard modal min median redirect=None decimal=4");
			//push to results table
			roiManager("Measure");

			headings=split(Table.headings, "\t");

			for(k=1; k<headings.length; k++){ //Skips the first heading: Index
				selectWindow("Results");
				col=Table.getColumn(headings[k]);
				selectWindow("Data");
				Table.setColumn(headings[k]+"_distance_to_"+suffixes[j]+"_in_"+unit, col);
			}
			selectWindow("Results");
			run("Close");
			selectWindow("Data");
		}
		
		Table.save(randomResultsPath+basename+".csv");
		run("Close");
		run("Close All");
	}
	
	
}

//------------------------------------------------------------------------------------
function removeCytoplasmRois(){
	for(i=roiManager("Count")-1; i>=0; i--){
		roiManager("Select", i);
		if(indexOf(Roi.getName, "Cytoplasm")!=-1) roiManager("Delete");
	}
	roiManager("Deselect");
}

//------------------------------------------------------------------------------------
function renameRois(prefix, start, stop, color){
	for(i=start; i<stop; i++){
		roiManager("Select", i);
		roiManager("Rename", prefix+"_"+(i-start+1));
		roiManager("Set Color", color);
	}
	roiManager("Deselect");
}
