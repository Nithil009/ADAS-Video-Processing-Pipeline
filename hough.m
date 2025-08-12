function hough(inputVideo)
    % DEMO_HOUGH_TRANSFORM Shows ROI edges vs Hough transform space
    % Input: Path to video file
    
    %% 1. Initialize Video
    if ~exist(inputVideo, 'file')
        error('Video file not found: %s', inputVideo);
    end
    vr = VideoReader(inputVideo);
    
    %% 2. Create Figure with 2 Panels
    fig = figure('Name', 'ROI vs Hough Transform', ...
                'Position', [100 100 800 400]);
    
    % Create 1x2 tile layout
    tiledlayout(1, 2, 'TileSpacing', 'compact');
    
    %% 3. Processing Parameters
    params.cannyThresh = [0.1 0.3];    % Canny thresholds
    params.roiHeight = 0.6;            % ROI covers lower 60%
    params.houghThresh = 0.3;          % Hough peak threshold
    params.gaussianSigma = 2;          % Blur strength
    params.thetaRange = -89:0.5:89;    % Hough theta range
    
    %% 4. Processing Loop
    try
        while hasFrame(vr) && isvalid(fig)
            % Read and preprocess frame
            frame = readFrame(vr);
            gray = im2gray(frame);
            blurred = imgaussfilt(gray, params.gaussianSigma);
            
            %% Stage 1: Edge Detection + ROI Masking
            edges = edge(blurred, 'Canny', params.cannyThresh);
            
            % Create trapezoidal ROI mask
            [rows, cols] = size(edges);
            roiY = round(params.roiHeight * rows);
            roiPoints = [1, rows; 
                        cols*0.4, roiY;
                        cols*0.6, roiY;
                        cols, rows];
            roiMask = poly2mask(roiPoints(:,1), roiPoints(:,2), rows, cols);
            roiEdges = edges & roiMask;
            
            %% Stage 2: Hough Transform
            [H, theta, rho] = hough(roiEdges, 'Theta', params.thetaRange);
            peaks = houghpeaks(H, 10, 'Threshold', params.houghThresh*max(H(:)));
            
            %% Visualization
            % 1. ROI Edges
            ax1 = nexttile(1);
            imshow(roiEdges, 'Parent', ax1);
            title('ROI Edges');
            hold(ax1, 'on');
            plot(ax1, roiPoints(:,1), roiPoints(:,2), 'r-', 'LineWidth', 2);
            plot(ax1, [roiPoints(end,1); roiPoints(1,1)], ...
                 [roiPoints(end,2); roiPoints(1,2)], 'r-', 'LineWidth', 2);
            hold(ax1, 'off');
            
            % 2. Hough Transform Space
            ax2 = nexttile(2);
            imshow(log(1+H), [], 'XData', theta, 'YData', rho, 'Parent', ax2);
            title('Hough Transform Space');
            xlabel('\theta (degrees)');
            ylabel('\rho (pixels)');
            axis(ax2, 'on');
            colormap(ax2, 'hot');
            colorbar(ax2);
            hold(ax2, 'on');
            plot(ax2, theta(peaks(:,2)), rho(peaks(:,1)), 's', ...
                 'Color', 'cyan', 'MarkerSize', 10);
            hold(ax2, 'off');
            
            drawnow;
            pause(1/vr.FrameRate);
        end
    catch ME
        disp('Error during processing:');
        disp(ME.message);
    end
    
    %% Cleanup
    if exist('vr', 'var')
        clear vr;
    end
    if isvalid(fig)
        close(fig);
    end
end