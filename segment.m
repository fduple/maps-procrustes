function out = segment(F)
% This script finds boundaries in an image file, segments the image and calls
% procrustes.m for each segment in turn, while outlining and numbering each
% segment visually over the input image file.
%
% It produces a PDF file containing the segmented, outlined and numbered image,
% plus the results of procrustes.m as called.
%
% Requirements (Tested under Ubuntu 18.04 and 20.04):
% sudo apt install octave octave-image imagemagick
%
% Example:
% Put procrustes.m and segment.m in the same directory as an image file;
%   octave ./segment.m to_be_segmented.png

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
% Version 0.9
% Date 2020-01-10

if exist("F")!=1                      %Filename to be processed
  arg_list = argv();
  if rows(arg_list)==1
    F=arg_list{1};
  else
    disp("Usage: octave segment.m <imagename>  (Image must be in current directory)")
    return
  endif
endif
% F="to_be_segmented.png"

pkg load image

if exist(F)==2
  l=imread(F);
else
  disp("Error: Image must exist in current directory")
  return
endif
if size(l,3)==3,
  l1=rgb2gray(l);                   %Make input grayscale if not
else
  l1=l;
endif
figure(3); imshow(l1)
disp('Move & resize figure, then press Enter');
pause
l1(l1<255-0)=0;                     %Makes grays black
l1(l1>0)=255;
l2=(1-bwfill(255-l1,1,1));          %Binary image showing segements only
margin=1-bwfill(255-l1,"holes");    %Binary image showing outside margin
l3=uint8(128*l2+96*margin+127);     %Segments white, borders black, margin gray
b=bwboundaries(l2);                 %Find boundaries of segments
figure(3); imshow(l3), pause(1)
hold on
disp([int2str(numel(b)),' segments found.'])
disp(" ")
for k = 1:numel(b);                 %Outline & number the sgments
  figure(3); plot (b{k}(:,2), b{k}(:,1), 'g', 'linewidth', 1);
  text(mean(b{k}(:,2)),mean(b{k}(:,1)),int2str(k));
endfor
[dir, name, ext] = fileparts(F);
print([name,'.pdf'],'-dpdf')        %Output PDF has same name as input file
pause(1)
mkdir('Results');
dlmwrite("Results/result.csv",["FileName",',',"Rectangle-ness [%]",',',"Area [pixels]",',,',datestr(now,31)],"-append","delimiter","");
for k = 1:numel(b);
  figure(3); fill(b{k}(:,2), b{k}(:,1), 'c')          %Show active segment in cyan
  text(mean(b{k}(:,2)),mean(b{k}(:,1)),int2str(k));   %Pleaace number of active segment into image
  bk=b{k}-[min(b{k}(:,1))-1-5,min(b{k}(:,2))-1-5];    %Margin of 5 pixels, left and top
  c=[];
  for a=1:rows(bk),  c(bk(a,1),bk(a,2))=255;  endfor  %Mark all boundaries in the segment as found
  c(rows(c)+5,columns(c)+5)=0;                        %Margin of 5 pixels, right and bottom
  d=imfill(c, "holes");                               %Fill inside boundary
  %figure(1), imshow(d)
  pause(0.1)
  N=[num2str(k, "%03.f"),'_',F];                      %Fixed length for numbers in filenames for better sorting
  imwrite(d,N);
  procrustes(N);                                      %Calls procrustes.m with filled shape as input
  delete(N);
  figure(3); fill(b{k}(:,2), b{k}(:,1), 'w')
  figure(3); plot (b{k}(:,2), b{k}(:,1), 'b', 'linewidth', 3);  %Mark finished segment with blue boundary
  text(mean(b{k}(:,2)),mean(b{k}(:,1)),int2str(k));
endfor
figure(3); hold off
disp("Press Enter to finish")
pause
