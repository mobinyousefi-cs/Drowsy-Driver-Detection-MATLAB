function frameOut = drawStatusOverlay(frameIn, isDrowsy, eyeOpenScore, ...
                                      closedFrameCount, faceBBox, eyeBBox, ...
                                      fps, cfg)
% drawStatusOverlay  Render overlays with detection results.
%
%   frameOut = drawStatusOverlay(frameIn, isDrowsy, eyeOpenScore,
%                                closedFrameCount, faceBBox, eyeBBox, fps, cfg)
%
%   Draws:
%     - Green or red status label (AWAKE / DROWSY)
%     - Face and eye bounding boxes
%     - Eye-openness score and closed-frame count (optional)
%     - Estimated FPS (optional)

    frameOut = frameIn;

    % Draw face and eye bounding boxes
    if ~isempty(faceBBox)
        frameOut = insertShape(frameOut, 'Rectangle', faceBBox, ...
            'Color', 'cyan', 'LineWidth', 2);
    end

    if ~isempty(eyeBBox)
        frameOut = insertShape(frameOut, 'Rectangle', eyeBBox, ...
            'Color', 'yellow', 'LineWidth', 2);
    end

    % Status label
    if isDrowsy
        statusText = 'DROWSY!';
        statusColor = 'red';
    else
        statusText = 'AWAKE';
        statusColor = 'green';
    end

    frameOut = insertText(frameOut, [10 10], statusText, ...
        'FontSize', 20, 'BoxColor', statusColor, 'BoxOpacity', 0.8, ...
        'TextColor', 'white');

    % Eye score and closed frame count
    yOffset = 40;
    infoLines = {};

    if cfg.showEyeScore
        if isnan(eyeOpenScore)
            infoLines{end+1} = sprintf('Eye score: NaN (no face/eye)'); %#ok<AGROW>
        else
            infoLines{end+1} = sprintf('Eye score: %.3f (thr=%.3f)', ...
                eyeOpenScore, cfg.eyeOpenThreshold); %#ok<AGROW>
        end
        infoLines{end+1} = sprintf('Closed frames: %d / %d', ...
            closedFrameCount, cfg.closedFramesForDrowsy); %#ok<AGROW>
    end

    if cfg.showFrameRate && ~isnan(fps)
        infoLines{end+1} = sprintf('FPS: %.1f', fps); %#ok<AGROW>
    end

    if ~isempty(infoLines)
        textCombined = strjoin(infoLines, '\n');
        frameOut = insertText(frameOut, [10 yOffset], textCombined, ...
            'FontSize', 16, 'BoxColor', 'black', 'BoxOpacity', 0.6, ...
            'TextColor', 'white');
    end
end