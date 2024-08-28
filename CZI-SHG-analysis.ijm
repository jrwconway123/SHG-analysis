//Defining directories for saving and analysis
dir = getDirectory("Select a directory containing one or several CZI files");
files = getFileList(dir);
saveDir1 = dir + "/00 Extracted Tifs/";
File.makeDirectory(saveDir1);
saveDir2 = dir + "/00 Analysis/";
File.makeDirectory(saveDir2);

//Define the channels
Auto_channel = getNumber("Please indicate the Autofluorescence channel, or select 0 if none", 1);
Transmitted_channel = getNumber("Now the Transmitted light channel, or select 0 if none", 2);
SHG_channel = getNumber("..and the SHG channel, dude", 3);

//Close anything that was left open
close("\\Others");
num = nImages;
for (j = 0; j < num; j++){
	close();
}

//Set batch mode and open CZI files for analysis
//setBatchMode(true);
k=0;
n=0;
run("Bio-Formats Macro Extensions");
for(f=0; f<files.length; f++) {
	if(endsWith(files[f], ".czi")) {
		k++;
		id = dir+files[f];
		Ext.setId(id);
		Ext.getSeriesCount(seriesCount);
		n+=seriesCount;
		for (i=0; i<seriesCount; i++) {
			run("Bio-Formats Importer", "open=["+id+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack"+(i+1));
			Title = getTitle();
			run("Z Project...", "projection=[Max Intensity]");
			saveAs("tiff", saveDir1+Title+"- Z projection multichannel.tif");
			rename("Image");
			close(Title);
			getDimensions(width, height, channels, slices, frames);
			if (channels > 1) {
				run("Split Channels");
			}
			
			//Organising the different channels
			if (Auto_channel > 0) { 
				selectWindow("C"+Auto_channel+"-Image");
    			//saveAs("tiff", saveDir2+Title+"- Autofluorescence.tif");
				run("Enhance Contrast", "saturated=0.35");
				close();
			}
			
			if (Transmitted_channel > 0) { 
				selectWindow("C"+Transmitted_channel+"-Image");
    			//saveAs("tiff", saveDir2+Title+"- Transmitted light.tif");
				run("Enhance Contrast", "saturated=0.35");
				close();
			}
			
			selectWindow("C"+SHG_channel+"-Image");
			run("Remove Outliers...", "radius=2 threshold=50 which=Bright stack");
			run("Despeckle", "Stack");
			run("Enhance Contrast", "saturated=0.35");
			run("Magenta");
			saveAs("tiff", saveDir2+Title+"- SHG BG corrected.tif");
			rename("SHG");
			setAutoThreshold("Li dark");
			run("Set Measurements...", "area mean standard modal min integrated area_fraction redirect=None decimal=3");
			run("Measure");
			if (isOpen("Results") == true) {
				selectWindow("Results");
				saveAs("Text", saveDir2+Title+" - SHG area and intensity");
				run("Close");
			}
			
			run("OrientationJ Measure");    //If this fails, then you need OrientationJ, which can be downloaded at the following link: http://bigwww.epfl.ch/demo/orientation/
			setTool("rectangle");
			waitForUser("Please perform the coherency analysis, save the results, then click Ok.");
			run("OrientationJ Analysis", "tensor=2.0 gradient=0 color-survey=on hsb=on hue=Orientation sat=Coherency bri=Original-Image radian=on ");
			selectWindow("OJ-Color-survey-1");
			run("Enhance Contrast", "saturated=0.35");
			saveAs("Tif", saveDir2+Title+" - Orientation image");
			close();
			close("SHG");
		}
	}
}
setBatchMode(false);
exit();