# maps-procrustes
These scripts implement Procrustes analysis.

Requirements (Tested in octave 4.2.2 and 5.2.0 under Ubuntu 18.04 and 20.04):  
```sudo apt install octave octave-image imagemagick```  
These scripts should also work in Matlab and under Windows.


### procrustes.m
Fits a supplied image of a single solid white shape on black background to a rectangle of the same area, by translation, scaling and rotation. The result is a percentage of area of the original shape that could be fitted to a rectangle.  
Accuracy of the fit is +- 1 pixels in translation & scale and +- 1 degree in rotation.

It produces the following in a "Results" directory:
1. An image prefixed with "s_", containing the Scaled, translated image
2. An image prefixed with "r_", containing the Rotated image
3. An image prefixed with "p_", containing the Procrustes non-overlapping parts in red
4. A comma-delimited file, "result.csv" appended with the latest image name,
   percentage of area of the shape that could be fitted to a rectangle and shape
   area size in pixels.

Example:  

Place procrustes.m in the same directory as all image files to be analysed;

For a single image file:  
```octave procrustes.m triangle.png```

For multiple image files:  
```find *.png -type f -exec octave procrustes.m '{}' \;```


### segment.m
Finds boundaries in an image file, segments the image and calls procrustes.m for each segment in turn, while outlining and numbering each segment visually over the input image file.

It produces a PDF file containing the segmented, outlined and numbered image, plus the results of procrustes.m as listed above.

Example:  

Place segment. and procrustes.m in same directory as image files:  
```octave ./segment.m to_be_segmented.png```
