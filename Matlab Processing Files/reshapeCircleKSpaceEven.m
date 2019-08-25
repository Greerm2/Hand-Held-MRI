function [ kSpaceImage ] = reshapeCircleKSpaceEven( kSpace,numSteps )
%RESHAPECIRCLEKSPACEEVEN Summary of this function goes here
%   Detailed explanation goes here
kSpaceImage = zeros(numSteps,numSteps)

%Start by setting the center Voxel.
voxX = ceil(numSteps/2);
voxZ = ceil(numSteps/2);
kSpaceImage(voxX,voxZ) = kSpace(1);

%Initialize the kIndex and the end points
kIndex = 2;
rightEnd = 1;
upEnd = 1;
leftEnd = 2;
downEnd = 2;

 %Main Loop    
    for main = 1: floor(numSteps/2)        
        %Right Loop... Add to column 1 (voxX)
        for right = 1:rightEnd
            voxX = voxX + 1;
            kSpaceImage(voxX,voxZ) = kSpace(kIndex);
            kIndex = kIndex + 1;
        end
        
        %Up Loop... Add to column 2(voxZ)
        for up = 1:upEnd 
            voxZ = voxZ + 1;
            kSpaceImage(voxX,voxZ) = kSpace(kIndex);
            kIndex = kIndex + 1;
        end
        
        if leftEnd == numSteps
            leftEnd = leftEnd - 1;
        end
        %Left Loop... Subtract from colum, 1(VoxX)
        for left = 1:leftEnd 
            voxX = voxX - 1;
            kSpaceImage(voxX,voxZ) = kSpace(kIndex);
            kIndex = kIndex + 1;
        end
        
        if downEnd < numSteps
            %Down Loop... Subtract from Column 2(voxZ)
            for down = 1:downEnd
                voxZ = voxZ - 1;
                kSpaceImage(voxX,voxZ) = kSpace(kIndex);
                kIndex = kIndex + 1;
            end
        end
        
        %Change end points for each loop
        rightEnd = rightEnd +2;
        upEnd = upEnd +2;
        leftEnd = leftEnd+2;
        downEnd = downEnd+2;        
    end
    
   

end

