            
function pencilROI_CMRI(hfig,action,color,lineWidth) 

%This is a freehand tool that can be used to draw ROI over images. Editing options are available to modify the ROIs.
%Function INTERPPOLYGON by Author: Jean-Yves Tinevez is required.
%Input arguments:
%hfig=Figure's handle
%action:
%- 'draw'(default): draw a new ROI with the selected color. Clicking over an existing ROI of the same selected color allows to modify it.
%- 'move': move an existing ROI.
%- 'color': changes the color of an existing ROI.
%- 'delete': delete an existing ROI.
%- 'polygon': modify an existing ROI. When the ROI is clicked many points are located on the ROI and each one can be moved. Right clicking on any of the points allows to %increment or reduce the number of points.
%- 'exit': exit function pencilROI
%-color: 'r'(default), 'b','g','m','y','c'
%-lineWidh

%--Example----
%I=dicomread('image.dcm');
%imshow(I,[]);
%pencilROI(gcf,'draw','r',1); %draw a red ROI size 1, or modify existing red ROI
%pencilROI(gcf,'draw','g',3); %draw a green ROI size 3, or modify existing green ROI
%pencilROI(gcf,'color','b'); %change color of existing ROI to blue
%pencilROI(gcf,'polygon'); %modify an existing ROI
%pencilROI(gcf,'move'); %move an existing ROI
%pencilROI(gcf,'exit'); %exit function pencilROI

%--To extract a Mask--
%rois=findobj(gcf,'type','line'); %here you will get a vector containing all drawn ROIs in the current figure
%coordx=(get(rois(1),'XData'))';
%coordy=(get(rois(1),'YData'))';
%color=get(rois(1),'Color'); %With the last 3 lines you get x, y and color of ROI number 1, the same for other ROIs.
%mask1=poly2mask(coordx,coordy,m,n) %the mask size will be m x n
%----INFO----
%Authors: - Andrés Larroza (anlarro@gmail.com)
%              - Silvia Ruiz (silviaruiz.es@gmail.com)
%Any modifications to the present code is permitted, but we will appreciate
%any feedback for improvement and if our names are always mentioned.

switch nargin
     case 4
      G.lineWidth=lineWidth;
      G.action=action;
      G.color=color(1);
    case 3
      G.lineWidth=1;
      G.action=action;
      G.color=color(1);
    case 2
      G.lineWidth=1;  
      G.action=action;
      G.color='r';
    case 1
      G.lineWidth=1;
      G.action='draw';
      G.color='r';
    case 0
      G.lineWidth=1;
      hfig=gcf;  
      G.action='draw';
      G.color='r';          
end

if ischar(G.action)
    if ~strcmp(G.action,'draw') && ~strcmp(G.action,'move') && ~strcmp(G.action,'exit') && ~strcmp(G.action,'delete') && ~strcmp(G.action,'color') && ~strcmp(G.action,'polygon')
        G.action='draw'; 
    end
else
    G.action='draw';
end

if ischar(G.color)
    if ~strcmp(G.color,'r') && ~strcmp(G.color,'b') && ~strcmp(G.color,'m') && ~strcmp(G.color,'y') && ~strcmp(G.color,'c') && ~strcmp(G.color,'g')
        G.color='r';
    end
else
    G.color='r';
end

ax=findobj(hfig,'type','axes'); 

G.ax=ax;
G.L=0;

G.coordAUX=[];

set(hfig,'userdata',G);

delete(findobj(hfig,'type','line','marker','.'));


iptPointerManager(hfig);
switch G.action
    case 'draw'
        for i=1:length(ax)
            set(findobj(ax(i),'Type','Image'),'ButtonDownFcn',@ClickedDown);
            set(findobj(ax(i),'type','line'),'ButtonDownFcn',@ROIclicked);
            enterFcn = @(hfig, currentPoint)set(hfig, 'Pointer', 'arrow');
        end
    case 'delete'
          for i=1:length(ax)
            set(findobj(ax(i),'Type','Image'),'ButtonDownFcn',[]);
            set(findobj(ax(i),'type','line'),'ButtonDownFcn',@ROIclicked);
            enterFcn = @(hfig, currentPoint)set(hfig, 'Pointer', 'crosshair'); 
          end  
     case 'color'
          for i=1:length(ax)
            set(findobj(ax(i),'Type','Image'),'ButtonDownFcn',[]);
            set(findobj(ax(i),'type','line'),'ButtonDownFcn',@ROIclicked);
            enterFcn = @(hfig, currentPoint)set(hfig, 'Pointer', 'hand');
          end 
    case 'move'
          for i=1:length(ax)
            set(findobj(ax(i),'Type','Image'),'ButtonDownFcn',[]);
            set(findobj(ax(i),'type','line'),'ButtonDownFcn',@startmovit);
            enterFcn = @(hfig, currentPoint)set(hfig, 'Pointer', 'fleur');
          end
    case 'polygon'
          for i=1:length(ax)
            set(findobj(ax(i),'Type','Image'),'ButtonDownFcn',[]);
            set(findobj(ax(i),'type','line'),'ButtonDownFcn',@ROIclicked);
            enterFcn = @(hfig, currentPoint)set(hfig, 'Pointer', 'cross');
          end
    case 'exit'
          for i=1:length(ax)
            set(findobj(ax(i),'Type','Image'),'ButtonDownFcn',[]);
            set(findobj(ax(i),'type','line'),'ButtonDownFcn',[]);
            enterFcn = @(hfig, currentPoint)set(hfig, 'Pointer', 'arrow');
          end
end
iptSetPointerBehavior(hfig, enterFcn);

%--------------------------------------------------------------------------
function ClickedDown(varargin)  %image clicked and action='draw'
       G=get(gcf,'userdata'); 
       switch get(gcf,'selectiontype')  
            case 'normal'
                  G.P=[];  
                  G.p=[];
                  
                  G.oldWBMFcn=get(gcf,'WindowButtonMotionFcn');
                  G.oldWBUFcn=get(gcf,'WindowButtonUpFcn');
                  set(gcf,'WindowButtonUpFcn',@ClickedUp);
                  set(gcf,'WindowButtonMotionFcn',@ondrag) 
                                    
                  cp=get(gca,'CurrentPoint');
                  G.P=[G.P;cp(1,:)];                           
                  G.L=1;                                        
        end
        set(gcf,'userdata',G);
    
function ondrag(varargin) %Drawing a new ROI

G=get(gcf,'userdata');
if G.L==1
     cp=get(gca,'CurrentPoint');
     G.P=[G.P;cp(1,:)];
    if isempty(G.p)
         hold on
         G.p0=plot(G.P(:,1),G.P(:,2),'color',G.color,'hittest','on','LineWidth',G.lineWidth);  
         G.p=G.p0;
    else
         set(G.p0,'Xdata',G.P(:,1),'Ydata',G.P(:,2));
    end
    set(gcf,'userdata',G);
end
       
function ClickedUp(varargin) %Stop drawing ROI

G=get(gcf,'userdata');
if strcmp(get(gcf,'SelectionType'),'normal')    
    set(gcf,'WindowButtonMotionFcn',[]);
    set(gcf,'WindowButtonUpFcn',[]);

x=G.P(:,1)';
y=G.P(:,2)';
NP=length(x); 


if length(x)>1  
  len=sqrt(...
  conv2(x,[1 -1],'valid').^2+...
  conv2(y,[1 -1],'valid').^2);
  len = [0;len(:)]; 
  len = cumsum(len);
  tempind = find(conv2(len,[1;-1],'valid')~=0); 
  len=[len(1);len(tempind+1)];
  x = [x(1) x(tempind+1)];
  y = [y(1) y(tempind+1)];  
  totallength=len(end);

    xr=interp1(len,x,linspace(0,totallength,NP+400),'linear');
  yr=interp1(len,y,linspace(0,totallength,NP+400),'linear');
  xr=xr(:);
  yr=yr(:);  
  
  x=[x(:);x(1)];
  y=[y(:);y(1)];
  
    len = sqrt(...
    conv2(x(:),[1;-1],'valid').^2+...
    conv2(y(:),[1;-1],'valid').^2);
  len = cumsum(len);
  len = [0;len(:)]; 
  tempind = find(abs(conv2(len,[1;-1],'valid'))>1e-3);
  len = [len(1);len(tempind+1)]; 
  x=[x(1);x(tempind+1)]; 
  y=[y(1);y(tempind+1)];   
  totallength=len(end);
  
  xr = interp1(len,x,linspace(0,totallength,(NP+400)),'linear');
  yr = interp1(len,y,linspace(0,totallength,(NP+400)),'linear');
  xr = xr(:);
  yr = yr(:);
           
  try
    delete(G.p0);
  catch
  end
  G.p0=plot(xr,yr,'color',G.color,'hittest','on','LineWidth',G.lineWidth);
  
  G.coordAUX=[xr yr]; 
  G.L=0;
  
  set(G.p0,'ButtonDownFcn',@ROIclicked);
  G.newROI=G.p0;
  set(gcf,'userdata',G);  
end
    set(gcf,'WindowButtonMotionFcn',G.oldWBMFcn);
    set(gcf,'WindowButtonUpFcn',G.oldWBUFcn);
end       
       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
function ROIclicked(varargin)  %Click on ROI to edit
       G=get(gcf,'userdata'); 
      
  switch G.action
      case 'draw'
       if get(gco,'Color')==char2rgb(G.color)   %We only edit is chosen color is the same as the ROI      
         G.oldCoord=[(get(gco,'XData'))' (get(gco,'YData'))'];
         switch get(gcf,'selectiontype')   
            case 'normal'
                  G.P=[];  
                  G.p=[];
                  G.oldWBMFcn=get(gcf,'WindowButtonMotionFcn');
                  G.oldWBUFcn=get(gcf,'WindowButtonUpFcn');
                  
                  set(gcf,'WindowButtonUpFcn',@ROIClickedUp);
                  set(gcf,'WindowButtonMotionFcn',@ROIondrag); 
                  cp=get(gca,'CurrentPoint');
                  G.P=[G.P;cp(1,:)];                           
                  G.L=1;                                          
                  set(gco,'LineWidth',G.lineWidth+1);   
                  G.p0=gco;
                  G.coordAUX=[];
                  G.coordAUX(:,1)=(get(G.p0,'XData'))';
                  G.coordAUX(:,2)=(get(G.p0,'YData'))';       
                  
                  set(gcf,'userdata',G);
        end  
       end 
      case 'delete'
          delete(gco);
          G.saveROI=true;
          set(gcf,'userdata',G);
      case 'color'
          G.color_ant=get(gco,'Color');
          set(gco,'Color',G.color);
          G.newROI=gco;
          oldWBMFcn=get(gcf,'WindowButtonMotionFcn');
          set(gcf,'WindowButtonMotionFcn',[]); 
          set(gcf,'userdata',G);  
          set(gcf,'WindowButtonMotionFcn',oldWBMFcn); 
      case 'polygon'
          switch get(gcf,'selectiontype')
              case 'normal'
                color=get(gco,'Color');  
                if isempty(findobj(gca,'type','line','marker','.','color',color))
                    delete(findobj(gcf,'type','line','marker','.'));
                    x=get(gco,'XData')';
                    y=get(gco,'YData')';
                    G.polygonHandle=gco;
                    G.XYpoly=[x y];
                    
                    x=x(1:round(length(x)/40):length(x));
                    y=y(1:round(length(y)/40):length(y));
          
                    G.points=[x y];
          
                    hold on;
                    for k=1:length(x)
                        hpoint=plot(x(k),y(k),'Marker','.','MarkerSize',15,'Color',color','LineStyle','none');
                        set(hpoint,'ButtonDownFcn',@PolygonClicked);
                    end
                    set(gcf,'userdata',G);
                end
            end
       end
            

function PolygonClicked(varargin) %Moving a point of the polygon     
     
G=get(gcf,'userdata'); 
   switch get(gcf,'selectiontype')
    case 'normal'
        G.oldWBMFcn=get(gcf,'WindowButtonMotionFcn');
        G.oldWBUFcn=get(gcf,'WindowButtonUpFcn');
        G.oldCoord=G.XYpoly;
      set(gcf,'WindowButtonUpFcn',@PolygonClickedUp);
      set(gcf,'WindowButtonMotionFcn',@PolygonOndrag); 
      G.startpoint=get(gca,'CurrentPoint');
        for c=1:length(G.points(:,1))
            if get(gco,'XData')==G.points(c,1) && get(gco,'YData')==G.points(c,2);
                G.points(:,1)=circshift(G.points(:,1),length(G.points(:,1))-c+2);   
                G.points(:,2)=circshift(G.points(:,2),length(G.points(:,2))-c+2);
                break;
            end
        end  
      
      inicio=find(G.XYpoly(:,1)==G.points(1,1) & G.XYpoly(:,2)==G.points(1,2)); 
      G.XYpoly(:,1)=circshift(G.XYpoly(:,1),length(G.XYpoly(:,1))-inicio+1);
      G.XYpoly(:,2)=circshift(G.XYpoly(:,2),length(G.XYpoly(:,2))-inicio+1);
      
      set(gco,'UserData',{get(gco,'XData') get(gco,'YData')}); 
      
       case 'alt'
          hcmenu=uicontextmenu; 
          G.hbdp=findall(gca,'Type','line');
          uimenu(hcmenu,'Label','More points','Callback',@increasePoints);
          uimenu(hcmenu,'Label','Less points','Callback',@decreasePoints);
          set(findall(gca,'Type','line'),'uicontextmenu',hcmenu);
    end
 set(gcf,'userdata',G); 
 
 function increasePoints(varargin)
G=get(gcf,'userdata');
    x=G.XYpoly(:,1);
    y=G.XYpoly(:,2);
    color=get(G.polygonHandle,'Color');
    if length(G.points(:,1))<length(x)  
        interval=round(length(x)/length(G.points(:,1)))/2;
        if interval<1
            interval=1;
        end
        x=x(1:interval:length(x));
        y=y(1:interval:length(y));
    end
    G.points=[x y];

    delete(findobj(gca,'type','line','marker','.'));
          
    for k=1:length(x)
        hpoint=plot(x(k),y(k),'Marker','.','MarkerSize',15,'Color',color','LineStyle','none');
        set(hpoint,'ButtonDownFcn',@PolygonClicked);
    end

 set(gcf,'userdata',G); 

function decreasePoints(varargin)
G=get(gcf,'userdata');
    x=G.XYpoly(:,1);
    y=G.XYpoly(:,2);
    color=get(G.polygonHandle,'Color');
    if length(G.points(:,1))>4  
        interval=round(length(x)/length(G.points(:,1)))*2;
        if interval>length(x)/4
            interval=round(length(x)/4);
        end
        x=x(1:interval:length(x));
        y=y(1:interval:length(y));
    end
    G.points=[x y];

    delete(findobj(gca,'type','line','marker','.'));
          
    for k=1:length(x)
        hpoint=plot(x(k),y(k),'Marker','.','MarkerSize',15,'Color',color','LineStyle','none');
        set(hpoint,'ButtonDownFcn',@PolygonClicked);
    end
 set(gcf,'userdata',G);  
       
function PolygonOndrag(varargin) %Dragging a point of the polygon

G = get(gcf,'UserData');

try
if isequal(G.startpoint,[])
    return
end
catch
end
    
                   
pos = get(gca,'CurrentPoint')-G.startpoint;
XYData = get(gco,'UserData');

G.points(2,1)=XYData{1}+pos(1,1);
G.points(2,2)=XYData{2}+pos(1,2);

inicio1=find(G.XYpoly(:,1)==G.points(1,1) & G.XYpoly(:,2)==G.points(1,2));
fin1=find(G.XYpoly(:,1)==G.points(3,1) & G.XYpoly(:,2)==G.points(3,2));
nrointerp=length(G.XYpoly(inicio1:fin1,1));

newpart1=interppolygon([[G.points(1,1) G.points(2,1)]' [G.points(1,2) G.points(2,2)]'],round(nrointerp/2),'spline');
newpart2=interppolygon([[G.points(2,1) G.points(3,1)]' [G.points(2,2) G.points(3,2)]'],round(nrointerp/2)+1,'spline');
newpart=[newpart1;newpart2(2:end,:)];

G.XYpoly(inicio1:length(newpart(:,1)),1)=newpart(:,1);
G.XYpoly(inicio1:length(newpart(:,2)),2)=newpart(:,2);

set(gco,'XData',G.points(2,1));
set(gco,'YData',G.points(2,2));
set(G.polygonHandle,'XData',G.XYpoly(:,1),'YData',G.XYpoly(:,2));
set(gcf,'UserData',G);

function PolygonClickedUp(varargin) 
G = get(gcf,'UserData');
G.newROI=G.polygonHandle;
set(gcf,'UserData',G);
set(gcf,'WindowButtonMotionFcn',G.oldWBMFcn);
set(gcf,'WindowButtonUpFcn',G.oldWBUFcn);
set(gco,'UserData','');

      
     
function ROIondrag(varargin) %editing a ROI

G=get(gcf,'userdata');
if G.L==1
     cp=get(gca,'CurrentPoint');
     G.P=[G.P;cp(1,:)];
    if isempty(G.p)
      hold on        
         G.p1=plot(G.P(:,1),G.P(:,2),'color',G.color,'hittest','on','LineWidth',G.lineWidth);  
         G.p=G.p1;
    else
          set(G.p1,'Xdata',G.P(:,1),'Ydata',G.P(:,2));   
    end
    set(gcf,'userdata',G);
end


function ROIClickedUp(varargin) %stop editing a ROI

G=get(gcf,'userdata');
if strcmp(get(gcf,'SelectionType'),'normal')
    set(gcf,'WindowButtonMotionFcn',[]);
    set(gcf,'WindowButtonUpFcn',[]);

x=G.P(:,1)';
y=G.P(:,2)';
NP=length(x); 


if length(x)>1  
  len=sqrt(...
  conv2(x,[1 -1],'valid').^2+...
  conv2(y,[1 -1],'valid').^2);
  len = [0;len(:)]; 
  len = cumsum(len);
  tempind = find(conv2(len,[1;-1],'valid')~=0); 
  len=[len(1);len(tempind+1)];
  x = [x(1) x(tempind+1)];
  y = [y(1) y(tempind+1)];  
  totallength=len(end);

  
  xr=interp1(len,x,linspace(0,totallength,NP+400),'linear');
  yr=interp1(len,y,linspace(0,totallength,NP+400),'linear');
  xr=xr(:);
  yr=yr(:);  
  

  contourx=xr;   
  contoury=yr;    
  
  
  [temp,startind]=min((G.coordAUX(:,1)-contourx(1)).^2+(G.coordAUX(:,2)-contoury(1)).^2);
  [temp,endind]=min((G.coordAUX(:,1)-contourx(end)).^2+(G.coordAUX(:,2)-contoury(end)).^2);
  if startind>endind
    temp=startind;
    startind=endind;
    endind=temp;
  end;

  part1x=G.coordAUX(startind:endind,1);
  part1y=G.coordAUX(startind:endind,2);

  part2x=[G.coordAUX(endind:end,1);G.coordAUX(2:startind,1)];
  part2y=[G.coordAUX(endind:end,2);G.coordAUX(2:startind,2)];

  if ...
    ((part1x(end)-contourx(1))^2+(part1y(end)-contoury(1))^2)< ...
    ((part1x(end)-contourx(end))^2+(part1y(end)-contoury(end))^2 )
    part1x=[part1x;contourx];
    part1y=[part1y;contoury];
  else
    part1x=[part1x;flipud(contourx)];
    part1y=[part1y;flipud(contoury)];
  end;
  area1=polyarea(part1x,part1y);
  
 
  if ...
    ((part2x(end)-contourx(1))^2+(part2y(end)-contoury(1))^2)< ...
    ((part2x(end)-contourx(end))^2+(part2y(end)-contoury(end))^2)
    part2x=[part2x;contourx];
    part2y=[part2y;contoury];
  else
    part2x=[part2x;flipud(contourx)];
    part2y=[part2y;flipud(contoury)];
  end;
  area2=polyarea(part2x,part2y);
  
  if area1>area2
    newcontourx=[part1x(:);part1x(1)];
    newcontoury=[part1y(:);part1y(1)];
  else
    newcontourx=[part2x(:);part2x(1)];
    newcontoury=[part2y(:);part2y(1)];
  end;
  newlen=sqrt(...
  conv2(newcontourx(:),[1;-1],'valid').^2+...
  conv2(newcontoury(:),[1;-1],'valid').^2);
  newlen=cumsum(newlen);
  newlen=[0;newlen(:)];  
  tempind=find(abs(conv2(newlen,[1;-1],'valid'))>1e-3);
  newlen=[newlen(1);newlen(tempind+1)];
  newcontourx=[newcontourx(1);newcontourx(tempind+1)];
  newcontoury=[newcontoury(1);newcontoury(tempind+1)]; 
  newtotallength=newlen(end);
  xr=interp1(newlen,newcontourx,linspace(0,newtotallength,NP+400),'linear');
  yr=interp1(newlen,newcontoury,linspace(0,newtotallength,NP+400),'linear');
  xr = xr(:);
  yr = yr(:);  
     
  try
  delete(G.p0)
  catch
  end
  delete(G.p1) 
  G.p0=plot(xr,yr,'color',G.color,'hittest','on','LineWidth',G.lineWidth);
  
   G.coordAUX=[xr yr];
  
    G.L=0;
    
    set(G.p0,'ButtonDownFcn',@ROIclicked);
    G.newROI=G.p0;
    set(gcf,'userdata',G); 
else
    set(G.p0,'LineWidth',G.lineWidth);
end   
        set(gcf,'WindowButtonMotionFcn',G.oldWBMFcn);
        set(gcf,'WindowButtonUpFcn',G.oldWBUFcn);
end

function startmovit(src,evnt) %extracted from function moveit2(Author: Anders Brun, anders@cb.uu.se)

G = get(gcf,'UserData');

G.currenthandle = src;
thisfig = gcbf();
G.oldCoord=[(get(gco,'XData'))' (get(gco,'YData'))'];
set(gco,'LineWidth',G.lineWidth+1);  
G.oldWBMFcn=get(gcf,'WindowButtonMotionFcn');
G.oldWBUFcn=get(gcf,'WindowButtonUpFcn');

set(thisfig,'WindowButtonMotionFcn',@movit);
set(thisfig,'WindowButtonUpFcn',@stopmovit);

% Store starting point of the object
G.startpoint = get(gca,'CurrentPoint');
set(G.currenthandle,'UserData',{get(G.currenthandle,'XData') get(G.currenthandle,'YData')});

set(gcf,'UserData',G);

function movit(src,evnt) %extracted from function moveit2(Author: Anders Brun, anders@cb.uu.se)

G = get(gcf,'UserData');

try
if isequal(G.startpoint,[])
    return
end
catch
end

% Do "smart" positioning of the object, relative to starting point...
pos = get(gca,'CurrentPoint')-G.startpoint;
XYData = get(G.currenthandle,'UserData');

set(G.currenthandle,'XData',XYData{1} + pos(1,1));
set(G.currenthandle,'YData',XYData{2} + pos(1,2));

set(gcf,'UserData',G);


function stopmovit(src,evnt) %extracted from function moveit2(Author: Anders Brun, anders@cb.uu.se)
thisfig = gcbf();
G = get(gcf,'UserData');

set(G.currenthandle,'ButtonDownFcn',@startmovit);
G.newROI=G.currenthandle;
G.startpoint=[];
set(G.currenthandle,'LineWidth',G.lineWidth);  
set(G.currenthandle,'UserData','');
set(gcf,'UserData',G);

set(gcf,'WindowButtonMotionFcn',G.oldWBMFcn);
set(gcf,'WindowButtonUpFcn',G.oldWBUFcn);

function rgbvec = char2rgb (charcolor)
rgbvec = zeros(length(charcolor), 3);
charwarning = false;
for j = 1:length(charcolor)
    switch(lower(charcolor(j)))
        case 'r'
            rgbvec(j,:) = [1 0 0];
        case 'g'
            rgbvec(j,:) = [0 1 0];
        case 'b'
            rgbvec(j,:) = [0 0 1];
        case 'c'
            rgbvec(j,:) = [0 1 1];
        case 'm'
            rgbvec(j,:) = [1 0 1];
        case 'y'
            rgbvec(j,:) = [1 1 0];
        case 'w'
            rgbvec(j,:) = [1 1 1];
        case 'k'
            rgbvec(j,:) = [0 0 0];
        otherwise
            charwarning = true;
    end
end

if (charwarning)
    warning('RGB2VEC:BADC', 'Only r,g,b,c,m,y,k,and w are recognized colors');
end