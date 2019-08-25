function [A,T2,asymp_int_kspace,image] = PEImageAnalysis( path,exptnum,exptnum2,nignore,navg,Aest,T2est,threshold,nrDataFiles,even )
%This function processing purely phase encoded MRI data collected on the
%single-sided, hand-held MRI sensor. The inputs to the function are:
% path: path to the folder where the data is stored
% exptnum: the experiment number for the "y" experiment
% exptnum2: the experiment number for the "x" experiment
% nignore: the number of echoes to ignore
% navg: number of echoes to average together to make a smoother looking
% decay (by default, set this to 1)
% Aest: the amplitude of the signal estimate. Used for T2 weighting of the
% echoes. For a multiexponential decay of n components, input a vector with
% the specified amplitude estimates.
% T2est: the estimated T2 of the signal. Also used for T2 weighting of the
% echoes.For a multiexponential decay of n components, input a vector with
% the specified amplitude estimates.
% threshold: A value entered to threshold away noise in kspace.
% nrDataFiles: set this to 1
% even: set this to 0 if you have an odd amount of pixels and 1 if you have
% an even amount of pixels.

% Read parameters
TE=read_kea_acqu(path,exptnum,'echoTime')*1e-3; % TE -> echo spacing (ms)
nDummy=read_kea_acqu(path,exptnum,'dummyEchoes'); % Number of dummy echoes
TE=TE*(nDummy+1);
DW=read_kea_acqu(path,exptnum,'dwellTime'); % DW -> dwell time (us)
nrEchoes = read_kea_acqu(path,exptnum,'nrEchoes'); %Number of Echoes
nrSteps = read_kea_acqu(path,exptnum, 'numSteps');
nrPoints = read_kea_acqu(path,exptnum,'nrPnts');

tvect=TE*linspace(1,nrEchoes,nrEchoes)';
disp(['Effective echo spacing = ' num2str(TE*1e3*navg) ' us']);

% data = zeros(nrEchoes*nrSteps^2,nrPoints*2);
% data2 = zeros(nrEchoes*nrSteps^2,nrPoints*2);

data = zeros(nrPoints,nrEchoes,nrSteps^2);
data2 = zeros(nrPoints,nrEchoes,nrSteps^2);
%close all;
pointsPerDataSet = nrSteps^2/(nrDataFiles);


'Loading Data...'
%Open all of the data files and store into proper array.
for i = 1:nrDataFiles
    filname1=[path '\' num2str(exptnum) '\kspace3d' num2str(i) '.3d'];
    filname2=[path '\' num2str(exptnum2) '\kspace3d' num2str(i) '.3d'];    
    data(:,:,(i*pointsPerDataSet-pointsPerDataSet)+1:i*pointsPerDataSet) = LoadProspaData(filname1);
    data2(:,:,(i*pointsPerDataSet-pointsPerDataSet)+1:i*pointsPerDataSet) = LoadProspaData(filname2);  
end


'Data Loaded'
sizdata=size(data);

% Create an empty array to hold the imported data.  This array will store
% the real data from the y data collection and the imaginary data from the
% x data collection.  It contains all of the raw data for each individual
% point in the image.  sizdata is divided by 2 because it contains both the
% real and imaginary parts of the data.

% Create an empty array to hold the echo_asymp data.  This data is the sum
% of all of the echoes, which will provide an image that is both T2 and Amplitude
%weighted. sizdata is divided by 2 for reason provided above.  There is one
%curve for each voxel in the data
echo_asymp=zeros(nrSteps^2,sizdata(1));
echo_asymp1=zeros(nrSteps^2,sizdata(1));
echo_asymp2=zeros(nrSteps^2,sizdata(1));

% Creating an empty array to store the integral of each of the echo_asymp
% values
asymp_int = zeros(1,nrSteps^2);

% This provides the acquisition time for
tacq=DW*linspace(-sizdata(1)/2,sizdata(1)/2,sizdata(1)); % us
tvect=TE*linspace(1,nrEchoes,nrEchoes)';

nexp=length(T2est); % Number of exponential components

%Initializes the signal estimate based on the initial values given.
sig_decay_est=zeros(1,nrEchoes)'; % Multi-exponential signal decay function

% Initializes the Amplitude and T2 value arrays
A = zeros(nrSteps,nrSteps);
T2 = zeros(nrSteps,nrSteps);
for j=1:nexp
    sig_decay_est=sig_decay_est+Aest(j)*exp(-tvect/T2est(j));
end

% Store the data from the two datasets into the complex data matrix. The
% matrix must be split into 3 parts. Steps, Echo, Data.  Since the raw data
% is in a 2D matrix, the j loop must continue counting up even after it has
% completeled one complete cycle.  echo_asymp is also calculated in this
% step.  There should be 1 echo_asymp value for every point.
for i = 1:nrSteps^2    
    sig_decay_est_counter = 1;    
    for j= 1:nrEchoes               
        if j> nignore
            %No T2-weighting
            %echo_asymp=echo_asymp+data_c(j,:)/(sizdata(1)-nignore);
            %T2-weighted echo_asymp(i,:)=echo_asymp(i,:)+squeeze(data_c(i,sig_decay_est_counter,:))'*sig_decay_est(sig_decay_est_counter)/(nrEchoes-nignore);
            echo_asymp1(i,:)=echo_asymp1(i,:)+squeeze(data(:,sig_decay_est_counter,i))'*sig_decay_est(sig_decay_est_counter);
            echo_asymp2(i,:)=echo_asymp2(i,:)+squeeze(data2(:,sig_decay_est_counter,i))'*sig_decay_est(sig_decay_est_counter);
            sig_decay_est_counter = sig_decay_est_counter + 1;
            end        
    end    
    echo_asymp(i,:) =real(echo_asymp1(i,:)) +1i*imag(echo_asymp2(i,:));  
    asymp_int(i)=trapz(tacq,echo_asymp(i,:)); % Raw echo integral
%     asymp_int(i)=sqrt(trapz(tacq,(echo_asymp(i,:)).^2)); % No phase    
%     asymp_int(i)=trapz(tacq,echo_asymp(i,:).*w); % Windowed
    
    end

%Convert Echo_asymp to a 2D matrix and then perform the FFT on each data
%point. Then reshape the Image space image to 1D array to extract the integral value of
%each pixel.  It will be reshaped after these values are extracted.  This
%is needed because the IFFT2 must be performed before extracting the
%values.
fftM = hamming(nrSteps);
mask = zeros(nrSteps,nrSteps);
for n = 1:nrSteps
    mask(:,n) = fftM;
end
mask = mask.*mask';

%Reshape asymp_int into an n x n array for an image.  This is for the
%circular data aquisition
if even == 1
    asymp_int_kspace = reshapeCircleKSpaceEven(asymp_int,nrSteps);
else 
    asymp_int_kspace = reshapeCircleKSpace(asymp_int,nrSteps);
end

%Plot an image of the kspace for asmp_int
figure
subplot(2,2,1),
imagesc(fliplr(abs(asymp_int_kspace)));
title('Echo integral k-space');
% colormap(gray)
% colorbar;

subplot(2,2,3),
%imagesc(medfilt2(abs((fftshift(ifft2(kMinus))))));
image = flipud((abs((fftshift(ifft2(asymp_int_kspace,256,256))))));
imagesc(image);
title('Echo integral shift');
% colormap('gray')
subplot(2,2,2),
thresh = asymp_int_kspace;
thresh(abs(thresh) < threshold) = 0;
thresh = wthresh(thresh,'s', threshold);

% image = flipud((abs((fftshift(ifft2(thresh,512,512))))));
imagesc((abs(thresh)));
title('Thresh')


subplot(2,2,4),
imagesc(flipud((abs((fftshift(ifft2(thresh,256,256)))))));
title('Thresh Shift')
set(gcf,'color','w');

figure;
imagesc(((abs((fftshift(ifft2(thresh)))))));
title('Thresh Shift');

set(gcf,'color','w');
colorbar;
save([path '\kSpace' num2str(exptnum) num2str(exptnum2)],'asymp_int_kspace');

figure
imageW = flipud((abs((fftshift(ifft2(asymp_int_kspace,512,512))))));
normImageW = imageW - min(imageW(:))
normImageW = normImageW ./ max(normImageW(:)) % *

image = normImageW;

end




