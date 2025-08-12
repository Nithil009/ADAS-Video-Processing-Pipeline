function dctComparison(inputVideo, Q_values)
    % DCTVIDEOCOMPARISON Shows original vs multiple DCT-compressed versions
    % Usage: dctVideoComparison('video.mp4', [1,2,5,7,10,13,15])
    
    %% 1. Initialize Video
    if ~exist(inputVideo, 'file')
        error('Video file not found: %s', inputVideo);
    end
    vr = VideoReader(inputVideo);
    
    %% 2. Create Figure with Tiled Layout
    fig = figure('Name', 'DCT Compression Comparison', ...
                'Position', [100 100 150*length(Q_values)+300 500]);
    
    % Create tiled layout (1 row for original + N rows for Q values)
    t = tiledlayout(fig, 2, length(Q_values), 'TileSpacing', 'compact');
    
    %% 3. Initialize Displays
    % Original video
    ax0 = nexttile(t, [1 length(Q_values)]);
    h0 = imshow(zeros(vr.Height, vr.Width, 3, 'uint8'));
    title(ax0, 'Original Video');
    
    % Create axes for each Q value
    h = gobjects(1, length(Q_values));
    for i = 1:length(Q_values)
        ax = nexttile(t);
        h(i) = imshow(zeros(vr.Height, vr.Width, 'uint8'));
        title(ax, sprintf('Q=%d', Q_values(i)));
    end
    
    %% 4. Real-Time Processing
    while hasFrame(vr) && isvalid(fig)
        % Read frame
        original = readFrame(vr);
        gray = im2double(rgb2gray(original));
        
        % Process for each Q value
        compressed_frames = cell(1, length(Q_values));
        for i = 1:length(Q_values)
            % DCT Compression Pipeline
            dctFun = @(block) round(dct2(block.data)/Q_values(i));
            quantized = blockproc(gray, [8 8], dctFun);
            
            % Reconstruction
            idctFun = @(block) idct2(block.data*Q_values(i));
            reconstructed = blockproc(quantized, [8 8], idctFun);
            
            compressed_frames{i} = im2uint8(reconstructed);
        end
        
        % Update displays
        set(h0, 'CData', original);
        for i = 1:length(Q_values)
            set(h(i), 'CData', compressed_frames{i});
        end
        
        pause(1/vr.FrameRate);
        drawnow;
    end
    
    close(vr);
    if isvalid(fig), close(fig); end
end