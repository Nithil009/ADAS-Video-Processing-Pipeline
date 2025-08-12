function cannyroi(inputVideo)
    % LANEDETECTIONWITHDCT Shows pipeline from DCT compression to lane detection
    % Compares DCT output with Canny edges and ROI masking
    % Usage: laneDetectionWithDCT('your_video.mp4')

    %% 1. Initialize Video
    if ~exist(inputVideo, 'file')
        error('Video file not found: %s', inputVideo);
    end
    vr = VideoReader(inputVideo);
    
    %% 2. Create Figure with Tiled Layout
    fig = figure('Name', 'Lane Detection Pipeline with DCT', ...
                'Position', [100 100 1200 400]);
    
    % Create 1x4 tile layout (DCT compressed | Canny edges | ROI edges | Combined)
    t = tiledlayout(1, 4, 'Padding', 'none', 'TileSpacing', 'compact');
    
    %% 3. Initialize Processing Parameters
    params.cannyThresh = [0.1 0.3];   % Canny edge thresholds
    params.roiHeight = 0.6;           % ROI covers lower 60% of image
    params.gaussianSigma = 2;         % Blurring strength
    params.dctThreshold = 0.1;        % DCT compression threshold (keep 10% of coeffs)
    
    %% 4. Processing Loop
    while hasFrame(vr) && isvalid(fig)
        % Read and preprocess frame
        frame = readFrame(vr);
        gray = rgb2gray(frame);
        
        %% Stage 0: DCT Compression (Your Existing Pipeline)
        dctFrame = performDCTCompression(gray, params.dctThreshold);
        
        %% Stage 1: Edge Detection on DCT Output
        blurred = imgaussfilt(dctFrame, params.gaussianSigma);
        edges = edge(blurred, 'Canny', params.cannyThresh);
        
        %% Stage 2: ROI Masking
        [rows, cols] = size(edges);
        roiY = round(params.roiHeight * rows);
        roiPoints = [1, rows; cols/2, roiY; cols, rows];
        roiMask = poly2mask(roiPoints(:,1), roiPoints(:,2), rows, cols);
        maskedEdges = edges & roiMask;
        
        %% Stage 3: Combined Visualization
        combinedVis = frame;
        [y, x] = find(maskedEdges);
        combinedVis(sub2ind(size(combinedVis), y, x)) = 255; % Mark edges in red
        
        %% Display Results
        % DCT compressed frame
        nexttile(1);
        imshow(dctFrame, 'Border', 'tight');
        title(sprintf('DCT Compressed (%.0f%% coeffs)', params.dctThreshold*100));
        
        % Canny edges
        nexttile(2);
        imshow(edges, 'Border', 'tight');
        title('Canny Edge Detection');
        
        % ROI masked edges
        nexttile(3);
        imshow(maskedEdges, 'Border', 'tight');
        title('ROI Masked Edges');
        
        % Combined output
        nexttile(4);
        imshow(combinedVis, 'Border', 'tight');
        title('Detected Lanes on Original');
        
        drawnow;
        pause(1/vr.FrameRate);
    end
    
    close(vr);
    if isvalid(fig), close(fig); end
end

%% Helper Function for DCT Compression
function compressed = performDCTCompression(img, threshold)
    % Perform block DCT compression (8x8 blocks)
    fun = @(block) dct2(block.data);
    dctImg = blockproc(img, [8 8], fun);
    
    % Threshold coefficients
    mask = abs(dctImg) > threshold*max(abs(dctImg(:)));
    compressedCoeffs = dctImg.*mask;
    
    % Inverse DCT
    fun = @(block) idct2(block.data);
    compressed = blockproc(compressedCoeffs, [8 8], fun);
    compressed = uint8(compressed);
end