# PencilROI

This is a Matlab freehand tool that can be used to draw ROIs over images. Editing options are available to modify the ROIs. 

## Prerequisites

Function INTERPPOLYGON by Author: Jean-Yves Tinevez is required.

## Input arguments:

* hfig=Figure's handle

### Action:
* 'draw'(default): draw a new ROI with the selected color. Clicking over an existing ROI of the same selected color allows to modify it.
* 'move': move an existing ROI.
* 'color': changes the color of an existing ROI.
* 'delete': delete an existing ROI.
* 'polygon': modify an existing ROI. When the ROI is clicked many points are located on the ROI and each one can be moved. Right clicking on any of the points allows to %increment or reduce the number of oints.
 'exit': exit function pencilROI
* color: 'r'(default), 'b','g','m','y','c'
* lineWidh

## Example
```
I=dicomread('image.dcm');
imshow(I,[]);
pencilROI(gcf,'draw','r',1); %draw a red ROI size 1, or modify existing red ROI
pencilROI(gcf,'draw','g',3); %draw a green ROI size 3, or modify existing green ROI
pencilROI(gcf,'color','b'); %change color of existing ROI to blue
pencilROI(gcf,'polygon'); %modify an existing ROI
pencilROI(gcf,'move'); %move an existing ROI
pencilROI(gcf,'exit'); %exit function pencilROI
```

### To extract a Mask

```
rois=findobj(gcf,'type','line'); %here you will get a vector containing all drawn ROIs in the current figure
coordx=(get(rois(1),'XData'))';
coordy=(get(rois(1),'YData'))';
color=get(rois(1),'Color'); %With the last 3 lines you get x, y and color of ROI number 1, the same for other ROIs.
ask1=poly2mask(coordx,coordy,m,n) %the mask size will be m x n
```

## Contact info
* **Andrés Larroza** - anlarro@gmail.com
* **Silvia Ruiz** - silviaruiz.es@gmail.com

## Licence
Any modifications to the present code is permitted, but we will appreciate
any feedback for improvement and if our names are always mentioned.
