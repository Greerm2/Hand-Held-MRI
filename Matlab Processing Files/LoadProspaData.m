function [varargout] = LoadProspaData(datapath)

% function [varargout] = LoadProspaData(datapath)
%
% A function for loading in .1d, .2d, .3d or .4d files from Prospa into Matlab.
%   
% datapath can either be relative or absolute, and can either be the name of
% the file directly (including the .1d, 2d, 3d or 4d extension) or a directory. If the directory
% contains only one prospa data file, that particular file is loaded. If the
% directory contains multiple prospa data files, no file is loaded and a list of
% available files is printed in the command line. In this case the file
% name must be given directly
%  
% If no input arguments are specified the current working directory is
% used.
%
%
% USAGE
%
% for xy data
%
% [x,y] = LoadProspaData('d:\data\1\xydata.1d')
%
% xydata.1d can be real or complex
%
% for all other data, 1 to 4 dimensions, real, complex or double precision
%
% M = LoadProspaData('d:\data\1\generic_data.1d')
% M = LoadProspaData('d:\data\1\generic_data.2d')
% M = LoadProspaData('d:\data\1\generic_data.3d')
% or
% M = LoadProspaData('d:\data\1\generic_data.4d')
%
%  (c) magritek 2010 
% 
%  Mark Hunter 24/06/2010

if nargin == 0;
    w = what;
    datapath = w(1).path;
end

if isempty(datapath)
        w = what;
    datapath = w(1).path;
end
    

%check to see if data path is 
f = dir(datapath);

[m,n] = size(f);

if m == 0
    str = ['''' datapath ''' does not exist'];
    error(str);
end
    
%dir

if f(1).isdir
    %datapath is a directory test to see if there are any data files

    for i = 1:1:length(f)
        if length(f(i).name)>3
            i;
            test1d(i) = sum( '.1d' == f(i).name((length(f(i).name)-2):length(f(i).name)) ) == 3;
            test2d(i) = sum( '.2d' == f(i).name((length(f(i).name)-2):length(f(i).name)) ) == 3;
            test3d(i) = sum( '.3d' == f(i).name((length(f(i).name)-2):length(f(i).name)) ) == 3;
            test4d(i) = sum( '.4d' == f(i).name((length(f(i).name)-2):length(f(i).name)) ) == 3;
        end
    end

    if sum(sum(test1d) + sum(test2d) + sum(test3d) + sum(test4d)) > 1
        II = find(test1d + test2d + test3d + test4d);
        datafname = f(II(1)).name;
        str = ['More than one .1d, .2d, .3d or .4d file in ''' datapath ''''];
        disp(str)
         for j = 1:1:length(II)
        str = f(II(j)).name;
        disp(str);
        end
        disp('no data file loaded')
        varargout = {[]};
        return
    end

    if sum(sum(test1d) + sum(test2d) + sum(test3d)) == 1
        II = find(test1d + test2d + test3d);
        datafname = f(II(1)).name;
    end
    
    if sum(sum(test1d) + sum(test2d) + sum(test3d)) == 0
        str = ['There are no .1d, .2d, .3d or .4d files in ''' datapath ''''];
        error(str)
    end
    

    datapath_and_fname = [datapath '\' datafname];
    
else
    isdatapathfile = 1;  %flag to say that parpath is a file name
    datapath_and_fname = datapath;
end


%opening the file

fid = fopen(datapath_and_fname);

if fid == -1;    
    str = ['Cannot open file ''' datapath_and_fname ''''];
    error(str);
end

%check for prospa data
A = fread(fid,8,'char');
if ~strcmp(sprintf('%c',flipud(A)),'DATAPROS')
str = ['The file ''' datapath_and_fname ''' is not Prospa Data'];
    error(str)
end

%check for version numer
A = fread(fid,4,'char');
ver_str = sprintf('%c',flipud(A));

%check for data type.
data_type = fread(fid,1,'int');
%500 real
%501 complex
%502 double real
%503 xy_real
%504 xy_comples

%get the array sizes
dim(1) = fread(fid,1,'int');
dim(2) = fread(fid,1,'int');
dim(3) = fread(fid,1,'int');
if sum(ver_str == 'V1.0') == 4;
    dim(4) = 1;
else
    dim(4) = fread(fid,1,'int');
end

%using the data_type load the data in the appropriate way

switch data_type

    case 504 %xy_complex data
        A = fread(fid,'float');
        X = zeros(dim(1),dim(2));
        X = A(1:dim(1));
        Y = A(dim(1)+1:2:3*dim(1)) + 1i*A(dim(1)+2:2:3*dim(1));
        varargout(1) = {X};
        varargout(2) = {Y};

    case 503 %xy_real data
        A = fread(fid,'float');
        X = zeros(dim(1),dim(2));
        X = A(1:dim(1));
        Y = A(dim(1)+1:2*dim(1));
        varargout(1) = {X};
        varargout(2) = {Y};

    case 502 %double real
        A = fread(fid,'double');
        B = zeros(dim(1),dim(2),dim(3),dim(4));
        B(:) = A(:);
        M = B;
        varargout(1) = {M};

    case 501 %complex y data
        A = fread(fid,'float');
        B = zeros(2*dim(1),dim(2),dim(3),dim(4));
        B(:) = A(:);
        M = B(1:2:2*dim(1),:,:,:) + B(2:2:2*dim(1),:,:,:)*1i;
        varargout(1) = {M};

    case 500  %y data
        A = fread(fid,'float');
        B = zeros(dim(1),dim(2),dim(3),dim(4));
        B(:) = A(:);
        M = B;
        varargout(1) = {M};

    otherwise
        error('Unknown prospa data type');

end


%closing the flie
fclose(fid);





