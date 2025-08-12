function optimizedroi(inputVideo)
    % ADAS Lane Detection System with optimized ROI
    % Usage: laneDetectionADAS('your_video.mp4')

    %% 1. Video Initialization
    if ~exist(inputVideo, 'file')
        error('Video file not found: %s', inputVideo);
    end
    
    vr = VideoReader(inputVideo);
    frameRate = vr.FrameRate;
    
    %% 2. Create ADAS Visualization Figure
    fig = figure('Name', 'ADAS Lane Detection System', ...
                'Position', [100 100 1400 800], ...
                'Color', [0.1 0.1 0.1]);
    
    % Create 2x3 tile layout
    t = tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    
    %% 3. ADAS Processing Parameters (Optimized for dashcam view)
    params = struct(...
        'cannyThresh', [0.08 0.2], ...    % More sensitive edge detection
        'gaussianSigma', 1.2, ...          % Slightly less blur
        'roiHeightRatio', 0.45, ...        % Smaller ROI height (45% of frame)
        'roiTopWidthRatio', 0.3, ...       % Narrower top width (30% of frame)
        'roiBottomWidthRatio', 0.8, ...    % Wider bottom width
        'houghThresh', 0.2, ...            % Lower threshold for more lines
        'minLineLength', 40, ...           % Shorter minimum line length
        'maxLineGap', 25, ...              % Smaller max gap between segments
        'angleThreshold', 25, ...          | % Slightly wider angle tolerance
        'houghPeaks', 8);                  % More potential lines
    
    %% 4. Main Processing Loop
    while hasFrame(vr) && isvalid(fig)
        % Read and preprocess frame
        frame = readFrame(vr);
        [height, width, ~] = size(frame);
        gray = rgb2gray(frame);
        blurred = imgaussfilt(gray, params.gaussianSigma);
        
        %% Stage 1: Edge Detection
        edges = edge(blurred, 'Canny', params.cannyThresh);
        displayFrame(edges, 1, 'Edge Detection', 'gray');
        
        %% Stage 2: Optimized Region of Interest (ROI)
        roiBottom = height;
        roiTop = height - round(params.roiHeightRatio * height);
        roiTopWidth = round(params.roiTopWidthRatio * width);
        roiBottomWidth = round(params.roiBottomWidthRatio * width);
        
        % Trapezoid points (adjusted for better lane focus)
        roiPoints = [...
            (width - roiTopWidth)/2, roiTop; ...     % Top-left
            (width + roiTopWidth)/2, roiTop; ...     % Top-right
            (width + roiBottomWidth)/2, roiBottom; ... % Bottom-right
            (width - roiBottomWidth)/2, roiBottom];    % Bottom-left
        
        roiMask = poly2mask(...
            roiPoints(:,1), roiPoints(:,2), height, width);
        maskedEdges = edges & roiMask;
        
        % Create ROI visualization
        roiVis = frame;
        roiVis = insertShape(roiVis, 'FilledPolygon', roiPoints, ...
                           'Color', [0 0.8 1], 'Opacity', 0.2); % Cyan color
        roiVis = insertShape(roiVis, 'Polygon', roiPoints, ...
                           'Color', 'cyan', 'LineWidth', 2);
        displayFrame(roiVis, 2, 'Optimized ROI', 'color');
        
        %% Stage 3: Hough Transform Processing
        [H, theta, rho] = hough(maskedEdges);
        peaks = houghpeaks(H, params.houghPeaks, 'Threshold', params.houghThresh*max(H(:)));
        lines = houghlines(maskedEdges, theta, rho, peaks, ...
                         'FillGap', params.maxLineGap, ...
                         'MinLength', params.minLineLength);
        
        % Filter lines by angle and position
        validLines = filterLaneLines(lines, params.angleThreshold, width, height);
        
        %% Stage 4: Visualizations
        % Hough Transform Space
        houghVis = imadjust(mat2gray(H));
        nexttile(t, 3);
        imshow(houghVis, 'XData', theta, 'YData', rho, 'InitialMagnification', 'fit');
        hold on;
        plot(theta(peaks(:,2)), rho(peaks(:,1)), 's', 'color', 'red', 'MarkerSize', 10);
        hold off;
        title('Hough Transform Space');
        xlabel('\theta (degrees)'); ylabel('\rho');
        axis on; axis normal;
        colormap(gca, 'hot');
        
        % Original frame
        displayFrame(frame, 4, 'Original Video', 'color');
        
        % Blurred frame
        displayFrame(blurred, 5, ['Gaussian Blur (\sigma=' num2str(params.gaussianSigma) ']'], 'gray');
        
        % Detected lanes with confidence indicators
        laneVis = frame;
        for k = 1:length(validLines)
            xy = [validLines(k).point1; validLines(k).point2];
            % Calculate line length for confidence visualization
            lineLength = norm(xy(1,:) - xy(2,:));
            lineWidth = max(2, min(6, round(lineLength/50)));
            
            laneVis = insertShape(laneVis, 'Line', xy, ...
                                'LineWidth', lineWidth, 'Color', 'green');
        end
        
        % Add lane departure warning if needed
        if length(validLines) < 2
            laneVis = insertText(laneVis, [width/2-100 50], 'LANE WARNING!', ...
                               'FontSize', 24, 'BoxColor', 'red', 'BoxOpacity', 0.8, ...
                               'TextColor', 'white', 'AnchorPoint', 'Center');
        end
        
        displayFrame(laneVis, 6, 'Lane Detection', 'color');
        
        drawnow limitrate;
        pause(1/frameRate);
    end
    
    close(vr);
    if isvalid(fig), close(fig); end
    
    %% Helper Functions
    function displayFrame(img, pos, titleText, imgType)
        nexttile(t, pos);
        if strcmp(imgType, 'gray')
            imshow(img, 'Border', 'tight');
            colormap(gca, 'gray');
        else
            imshow(img, 'Border', 'tight');
        end
        title(titleText, 'Color', 'white', 'FontSize', 12);
        set(gca, 'FontSize', 10);
    end
    
    function filteredLines = filterLaneLines(lines, angleThreshold, imgWidth, imgHeight)
        filteredLines = struct('point1', {}, 'point2', {}, 'theta', {}, 'rho', {});
        if isempty(lines)
            return;
        end
        
        % Calculate expected lane positions
        leftLaneRegion = [1, imgWidth/2];
        rightLaneRegion = [imgWidth/2, imgWidth];
        
        for k = 1:length(lines)
            xy = [lines(k).point1; lines(k).point2];
            
            % Calculate line angle (convert to degrees)
            angle = atan2d(xy(2,2) - xy(1,2), xy(2,1) - xy(1,1));
            
            % Check if line is in expected lane regions
            xCenter = mean(xy(:,1));
            if xCenter < imgWidth/2 % Left lane candidate
                expectedAngle = -75; % Left lane angle
            else % Right lane candidate
                expectedAngle = 75;  % Right lane angle
            end
            
            % Keep lines within angle threshold of expected lane angles
            if abs(angle - expectedAngle) < angleThreshold
                filteredLines(end+1) = lines(k);
            end
        end
    end
end