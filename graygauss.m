function graygauss(inputVideo)
    % GRAYGAUSS Shows all video processing stages in one window
    % Displays original, grayscale, and blurred video in tiled layout
    % Usage: graygauss('video_path.mp4')

    %% 1. Initialize Video Reader
    if ~exist(inputVideo, 'file')
        error('Video file not found: %s', inputVideo);
    end
    vr = VideoReader(inputVideo);
    
    %% 2. Create Single Figure with Tiled Layout
    fig = figure('Name', 'Video Processing Pipeline', ...
                'Position', [100 100 1200 800], ...
                'NumberTitle', 'off');
    
    % Create tiled layout (1 row, 3 columns)
    t = tiledlayout(fig, 1, 3, 'Padding', 'none', 'TileSpacing', 'compact');
    
    % Create axes for each video stream
    ax1 = nexttile(t); h1 = imshow(zeros(vr.Height, vr.Width, 3, 'uint8'));
    title(ax1, 'Original Video');
    
    ax2 = nexttile(t); h2 = imshow(zeros(vr.Height, vr.Width, 'uint8'));
    title(ax2, 'Grayscale Conversion');
    
    ax3 = nexttile(t); h3 = imshow(zeros(vr.Height, vr.Width, 'uint8'));
    title(ax3, 'Gaussian Blur (σ=2)');
    
    %% 3. Real-Time Processing Loop
    try
        while hasFrame(vr) && isvalid(fig)
            % Read current frame
            originalFrame = readFrame(vr);
            
            % Processing pipeline
            grayFrame = rgb2gray(originalFrame);
            blurredFrame = imgaussfilt(grayFrame, 2);
            
            % Update displays
            set(h1, 'CData', originalFrame);
            set(h2, 'CData', grayFrame);
            set(h3, 'CData', blurredFrame);
            
            % Control playback speed and update display
            pause(1/vr.FrameRate);
            drawnow;
        end
    catch ME
        disp(['Processing stopped: ' ME.message]);
    end
    
    %% 4. Cleanup
    if isvalid(fig), close(fig); end
    close(vr);
end