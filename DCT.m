function DCT(inputVideo, Q)
    % DCTVIDEOCOMPRESSION Demonstrates DCT-based video compression
    % Shows original, compressed, and error frames side-by-side
    % Usage: dctVideoCompression('video.mp4', Q)
    %   Q: Quantization factor (higher = more compression)

    %% 1. Initialize Video
    if ~exist(inputVideo, 'file')
        error('Video file not found: %s', inputVideo);
    end
    vr = VideoReader(inputVideo);
    
    %% 2. Create Display Window
    fig = figure('Name', 'DCT Video Compression', ...
                'Position', [100 100 1200 400]);
    
    % Original video
    ax1 = subplot(1,3,1);
    h1 = imshow(zeros(vr.Height, vr.Width, 3, 'uint8'));
    title(sprintf('Original\n(%dx%d)', vr.Width, vr.Height));
    
    % Compressed video
    ax2 = subplot(1,3,2);
    h2 = imshow(zeros(vr.Height, vr.Width, 'uint8'));
    title(sprintf('DCT Compressed\nQ=%d, 8x8 blocks', Q));
    
    % Error visualization
    ax3 = subplot(1,3,3);
    h3 = imshow(zeros(vr.Height, vr.Width, 'uint8'));
    title('Compression Error');
    
    %% 3. DCT Processing Pipeline
    while hasFrame(vr) && isvalid(fig)
        % Read and convert frame
        original = readFrame(vr);
        gray = im2double(rgb2gray(original));
        
        % DCT Compression
        dctFun = @(block) round(dct2(block.data) ./ Q);
        dctBlocks = blockproc(gray, [8 8], dctFun);
        
        % Reconstruction (inverse DCT)
        idctFun = @(block) idct2(block.data * Q);
        compressed = blockproc(dctBlocks, [8 8], idctFun);
        
        % Convert back to display format
        compressed8 = im2uint8(compressed);
        errorImg = im2uint8(abs(gray - compressed));
        
        % Update displays
        set(h1, 'CData', original);
        set(h2, 'CData', compressed8);
        set(h3, 'CData', errorImg);
        
        % Control playback speed
        pause(1/vr.FrameRate);
        drawnow;
    end
    
    %% 4. Cleanup
    if isvalid(fig), close(fig); end
    close(vr);
end