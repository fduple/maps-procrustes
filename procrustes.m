function out = procrustes(F)
  % Fits a supplied image of a single solid white shape on black background to a
  % rectangle of the same area, by translation, scaling and rotation. The result is
  % a percentage of area of the original shape that could be fitted to a rectangle.
  % Images with X or Y shape dimensions of more than 1000/sqrt(2)=707, is
  % downsized. Accuracy of the fit is +- 1 pixels in translation & scale
  % and +- 1 degree in rotation.
  %
  % It produces the following in a "Results" directory:
  % 1. An image prefixed with "s_", containing the Scaled, translated image
  % 2. An image prefixed with "r_", containing the Rotated image
  % 3. An image prefixed with "p_", containing the Procrustes non-overlapping parts in red
  % 4. A comma-delimited file, "result.csv" appended with the latest image name
  %    and percentage of area of the shape that could be fitted to a rectangle.
  %
  % Requirements (Tested under Ubuntu 18.04 and 20.04):
  % sudo apt install octave octave-image imagemagick
  %
  % Examples:
  % Put procrustes.m in same the directory as all image files to be analysed.
  % For a single image file:
  %   octave procrustes.m triangle.png
  % For multiple image files:
  %   find *.png -type f -exec octave procrustes.m '{}' \;

%{
MIT Licence

Contributors:
Copyright 2014-2021 Francois E. du Plessis

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%}
% Version 0.92
% Date 2020-01-10

if exist("F")!=1                    %Filename to be processed
  arg_list = argv();
  if rows(arg_list)==1
    F=arg_list{1};
  else
    disp("Usage: octave procrustes.m <imagename>  (Image must be in current directory)")
    exit(1)
  endif
endif

pkg load image;

function RelEr = Rot (Im, deg, saveFile)            %Function expects square image
  Im=round(Im);
  Rs=rows(Im);
  Ss=sum(sum(Im));                  %Sum of all pixel values, for normalisation
  D10=imrotate(Im,deg,'bilinear','crop');       %Image Im rotated deg degrees
  Wx=sum(sum(D10).* abs( (0.25-Rs/2):(Rs/2-0.75) ))/Ss*4;      %Average width
  Wy=sum(sum(D10').*abs( (0.25-Rs/2):(Rs/2-0.75) ))/Ss*4;     %Average height
  Sc=sqrt(Ss/(255*Wx*Wy));                      %Scaling required
  Cr1=round(Rs/2-Sc*Wy/2)+1;                    %Corners for square; top
  Cr2=round(Rs/2+Sc*Wy/2);                      %Corners for square; bottom
  Cr3=round(Rs/2-Sc*Wx/2)+1;                    %Corners for square; left
  Cr4=round(Rs/2+Sc*Wx/2);                      %Corners for square; right
  R10=zeros(Rs);                                %Reference image for rectangle
  R10(Cr1:Cr2,Cr3:Cr4)=255;                     %Create white rectangle
  E10=uint8(abs(D10-R10));                      %Error image of differences
  Fr=Fg=Fb=D10;                                 %Evaluated shape in white
  Fr(E10>0)=E10(E10>0);                         %Non-overlapping areas red
  Fg(E10>0)=0.2*E10(E10>0);                     %Bit of green and blue for
  Fb=Fg;                                        % a more visible colour
  F10=uint8(cat(3,Fr,Fg,Fb));                   %Final image for display
  if size(saveFile)
    figure(1), imshow(uint8(D10)), pause(0.5)   %Rotated shape as evaluated
    imwrite(uint8(Im),['Results/s_',saveFile])  %Scaled & centred shape saved
    imwrite(uint8(D10),['Results/r_',saveFile]) %Rotated shape saved
    imwrite(F10,['Results/p_',saveFile])        %Procrustes differences saved
  endif
  figure(1), imshow(F10),   pause(0.05)
  RelEr=sum(sum(E10))/Ss/2*100;                 %All non-matching pixels, normalised
endfunction

if exist(F)==2
  A10=imread(F);
else
  disp("Error: Image must exist in current directory")
  return
endif
if size(A10,3)==3,
  B10=double(rgb2gray(A10));                     %Make input grayscale if not
else
  B10=double(A10);
endif
B10=B10-min(min(B10));
B10=B10/max(max(B10))*255;                %Intensity stretched
El=min(find(sum(B10)>0));
Er=max(find(sum(B10)>0));                 %Find edges of shapes
Et=min(find(sum(B10')>0));
Eb=max(find(sum(B10')>0));
Over=max(Er-El,Eb-Et)/707;                %Oversized relative to square that can rotatae in an image of size 1000
if Over>1
  B10=imresize(B10,1/Over);               %Resize images with an object larger than 1000/sqrt(2)=707 pixels.
else
  Over=1;
endif
Tot=sum(sum(B10));                          %Total sum of all pixel values, for normalisation
Area=Tot/255;                               %Area in pixels
CMx=sum(sum(B10).*[1:columns(B10)])/Tot;    %Center of Mass, x & y
CMy=sum(sum(B10').*[1:rows(B10)])/Tot;
Sz=max([size(B10),10+1.42*2*([Er/Over-CMx, CMx-El/Over, Eb/Over-CMy, CMy-Et/Over])]);
Sz=ceil(Sz/2)*2;                            %Make Size even
B10(Sz,Sz)=0;                               %Change canvas size to a square of suitable size
figure(1), imshow(uint8(B10)),  pause(0.5)
%figure(2), plot([sum(B10); sum(B10')]')
C10=imtranslate(B10,round(Sz/2+0.5-CMx),round(-Sz/2-0.5+CMy));  %Center of mass centred
figure(1), imshow(uint8(C10)),  pause(0.1)
for n=1:9                                   %Rough search for best rotation angle
  d=(n-1)*10;                               %degrees 0:10:80
  Sq(n)=100-Rot(C10,d,"");                     %"Squareness" calculated (actually rectangle-ness)
  %disp([d Sq(n)])
endfor
[hi,ind]=max(Sq); ang=(ind-1)*10;           %Maximum Squareness gives best angle, +- 10 degrees
Sq=[]; Sq(3)=hi;
for n=[1 2 4 5]                             %Finer search for best rotation angle
  d=ang+(n-3)*4;
  Sq(n)=100-Rot(C10,d,"");
  %disp([d Sq(n)])
endfor
[hi,ind]=max(Sq); ang=ang+(ind-3)*4;        %Maximum Squareness gives best angle, +- 4 degrees
Sq=[]; Sq(4)=hi;
for n=[1:3 5:7]                             %Final search for best rotation angle
  d=ang+(n-4)*1;
  Sq(n)=100-Rot(C10,d,"");
  %disp([d Sq(n)])
endfor
[hi,ind]=max(Sq); ang=ang+(ind-4)*1;        %Maximum Squareness gives best angle, +- 1 degrees
mkdir('Results');
Sq=100-Rot(C10,ang,F);                      %Run Rot function with final angle, saving true
out=[F,',',num2str(Sq),',',num2str(Area)];
disp(out);
dlmwrite("Results/result.csv",[F,',',num2str(Sq),',',num2str(Area)],"-append","delimiter","");
pause(1)

endfunction
