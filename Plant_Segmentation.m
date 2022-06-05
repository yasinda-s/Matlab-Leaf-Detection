%% clear memory and close windows
close all
clear

%% all .png files in this directory will be read (plant001,plant002,plant003 must be in same directory as this code)
files = dir('*.png'); 
fileCount = 0;

for file = 1:length(files)
    %% read image
    filename = files(file).name;
    img = imread(filename);
    fileCount = fileCount + 1;
    subplot(3,2,fileCount);
    imshow(img)
    title("Original Image")

    %% sharpen image
    img = imsharpen(img,'Radius',2,'Amount',1);
    % imshow(img)
    % title("Sharpened Image")

    %% apply gaussian
    img = imgaussfilt(img,1.14);
    % imshow(img)
    % title("Gaussian Applied")

    % Get HSV channels
    HSV=rgb2hsv(img);
    H=HSV(:,:,1);
    S=HSV(:,:,2);
    V=HSV(:,:,3);
    % imshow(V)
    % title("Value color space")

    %% get R, G, B colour channels
    R = img(:,:,1);
    G = img(:,:,2);
    B = img(:,:,3);

    %% get greeness of image
    greeness = G - (R + B)/2;
    % imshow(greeness)
    % title("Greeness retained from image")

    %% normalize to make it easier to work with values
    normalizedGreeness = mat2gray(greeness);
    % imshow(normalizedGreeness)
    % title("Normalized greeness")

    %% threshold value space of image based on greeness
    threshold = normalizedGreeness<=0.19;
    % imshow(threshold)
    % title("Threshold to be applied on V")
    V(threshold)=0;
    % imshow(V);
    % title("Greeness Thresholded V")

    %% peform binarizing with otsu
    level=graythresh(V);
    bw=imbinarize(V, level);
    % imshow(bw)
    % title("Binarized Image")

    %% retain the largest component
    bw = bwareafilt(bw,1);
    % imshow(bw)
    % title("Largest blob")

    %% create mask for V value
    background_mask = bw==0;
    V(background_mask)=0;
    V=medfilt2(V, [7 7]);
    % imshow(V);
    % title("Masked grayscale image based on V")

    %% edge detection using canny
    canny=edge(V, "Canny", [0.01 0.19]);
    % imshow(canny);
    % title("Canny edge detection")

    %% masking to add the edges onto the binarize image
    edge_mask = canny==1;
    bw(edge_mask)=0;
    % imshow(bw);
    % title("Canny masked to BW")

    %% image opening to get rid of edge noise
    se = strel('disk',1);
    bw = imopen(bw,se);
    % imshow(bw)
    % title("Image Opening to remove pixels")

    %% watershed segmentation
    % imshow(~bw)
    % -bwdist(~bw);
    distance = -bwdist(~bw);
    % imshow(distance,[])

    mask = imextendedmin(distance,1.6);
    % imshow(mask);
    % title("Mask based on extendedmin")

    distance2 = imimposemin(distance,mask);
    % imshow(distance2,[])
    % title("Imposed Minima")
    segment = watershed(distance2);
    % imshow(Ld2,[])
    % title("Watershed on Imposed distance")
    bw2 = bw;
    bw2(segment == 0) = 0;
    % imshow(BW2)
    % title("Binary image")

    %% label leaves
    [leaves, n] = bwlabel(bw2);

    %% add random color to leaves  
    leaves_copy = leaves;
    leaves_RGB = 255 * repmat(uint8(leaves), 1, 1, 3); 
    random_RGBArray = randi(255,1,3);

    [rows, cols] = size(leaves);

    for leaf = 1:n
        for row = 1:rows
            for col = 1:cols
                if leaves_copy(row,col) == leaf
                    leaves_RGB(row, col, :) = random_RGBArray;
                end
                %leaves_copy(row,col)
            end
        end
        random_RGBArray = randi(255,1,3);
    end

    %% print results
    fileCount = fileCount + 1;
    subplot(3,2,fileCount);
    imshow(leaves_RGB)
    title("Final Image");
    
end
