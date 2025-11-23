classdef DrowsinessDetector < handle
% DrowsinessDetector  Main class driving frame acquisition and detection.
%
%   detector = DrowsinessDetector(cfg)
%   detector.run()
%
%   The class manages:
%       - video source (webcam or file)
%       - face and eye detectors
%       - eye-openness scoring
%       - temporal drowsiness logic
%       - visualization and key handling

    properties (Access = private)
        cfg                 % configuration struct
        videoSource         % webcam object or VideoReader
        useWebcam logical   % flag
        faceDetector        % vision.CascadeObjectDetector
        eyeDetector         % vision.CascadeObjectDetector
        closedFrameCount    % consecutive closed-eye frames
        isDrowsy logical    % current drowsiness state
        figHandle           % figure handle for display
        axHandle            % axes handle
        lastFrameTime       % for FPS estimation
        frameCounter        % processed frame count
    end

    methods
        function obj = DrowsinessDetector(cfg)
            % Constructor: store config and initialize components.
            obj.cfg = cfg;
            obj.closedFrameCount = 0;
            obj.isDrowsy = false;
            obj.frameCounter = 0;

            % Initialize detectors (Viola-Jones)
            [obj.faceDetector, obj.eyeDetector] = initDetectors(cfg);

            % Setup video source
            if cfg.useWebcam
                try
                    cams = webcamlist;
                    assert(~isempty(cams), 'No webcams detected on this system.');
                    obj.videoSource = webcam(cfg.webcamIndex);
                    obj.useWebcam = true;
                    fprintf('[INFO] Using webcam: %s\n', cams{cfg.webcamIndex});
                catch ME
                    error('Failed to initialize webcam: %s', ME.message);
                end
            else
                assert(isfile(cfg.videoFile), 'Video file not found: %s', cfg.videoFile);
                obj.videoSource = VideoReader(cfg.videoFile);
                obj.useWebcam = false;
                fprintf('[INFO] Using video file: %s\n', cfg.videoFile);
            end

            % Initialize display
            obj.figHandle = figure('Name', 'Drowsy Driver Detection', ...
                                   'NumberTitle', 'off', ...
                                   'KeyPressFcn', @(src,evt)obj.onKeyPress(evt));
            obj.axHandle = axes('Parent', obj.figHandle);
            axis(obj.axHandle, 'image');
            obj.lastFrameTime = tic;
        end

        function run(obj)
            % run  Main loop: capture frames, analyze, and display.

            fprintf('[INFO] Starting detection loop. Press "q" to quit.\n');
            startTime = tic;

            while ishghandle(obj.figHandle)
                % Break if max runtime exceeded (if configured)
                if obj.cfg.maxRuntimeSeconds > 0 && ...
                        toc(startTime) > obj.cfg.maxRuntimeSeconds
                    fprintf('[INFO] Max runtime reached. Stopping.\n');
                    break;
                end

                frame = obj.readFrame();
                if isempty(frame)
                    fprintf('[INFO] No more frames. Stopping.\n');
                    break;
                end

                frame = obj.resizeFrame(frame);

                % Analyze frame
                [eyeOpenScore, faceBBox, eyeBBox] = obj.analyzeFrame(frame);
                [obj.isDrowsy, obj.closedFrameCount] = obj.updateDrowsinessState(eyeOpenScore);

                % FPS estimation
                currentTime = toc(obj.lastFrameTime);
                obj.lastFrameTime = tic;
                if currentTime > 0
                    fps = 1 / currentTime;
                else
                    fps = NaN;
                end

                % Draw overlay
                frameOut = drawStatusOverlay(frame, obj.isDrowsy, eyeOpenScore, ...
                                             obj.closedFrameCount, faceBBox, eyeBBox, ...
                                             fps, obj.cfg);

                % Display frame
                imshow(frameOut, 'Parent', obj.axHandle);
                drawnow limitrate;

                % Acoustic alert
                if obj.isDrowsy && obj.cfg.enableBeep
                    beep;
                end

                % Sleep a bit if we are faster than target FPS
                obj.frameCounter = obj.frameCounter + 1;
                if obj.cfg.targetFps > 0 && ~isnan(fps) && fps > obj.cfg.targetFps
                    pause(1/obj.cfg.targetFps);
                end
            end

            fprintf('[INFO] Detection loop terminated.\n');
        end

        function delete(obj)
            % delete  Clean up resources.
            if ~isempty(obj.videoSource)
                if obj.useWebcam
                    clear obj.videoSource; %#ok<CLSCR>
                else
                    % VideoReader does not require explicit release
                end
            end

            if ishghandle(obj.figHandle)
                close(obj.figHandle);
            end
        end
    end

    methods (Access = private)
        function frame = readFrame(obj)
            % readFrame  Get next frame from webcam or video file.
            if obj.useWebcam
                try
                    frame = snapshot(obj.videoSource);
                catch
                    frame = [];
                end
            else
                if hasFrame(obj.videoSource)
                    frame = readFrame(obj.videoSource);
                else
                    frame = [];
                end
            end
        end

        function frameOut = resizeFrame(obj, frameIn)
            % resizeFrame  Resize input frame to configured target size.
            sz = size(frameIn);
            if sz(2) ~= obj.cfg.targetFrameWidth || sz(1) ~= obj.cfg.targetFrameHeight
                frameOut = imresize(frameIn, ...
                    [obj.cfg.targetFrameHeight, obj.cfg.targetFrameWidth]);
            else
                frameOut = frameIn;
            end
        end

        function [eyeOpenScore, faceBBox, eyeBBox] = analyzeFrame(obj, frame)
            % analyzeFrame  Detect face, then eyes, and compute eye-openness score.

            % Defaults
            faceBBox = [];
            eyeBBox  = [];
            eyeOpenScore = NaN;

            gray = rgb2gray(frame);

            % Face detection
            bboxesFace = obj.faceDetector.step(gray);
            if isempty(bboxesFace)
                return; % no face, keep NaN score
            end

            % Choose the largest face
            [~, idxMax] = max(bboxesFace(:,3).*bboxesFace(:,4));
            faceBBox = bboxesFace(idxMax,:);

            % Crop face region
            faceROI = imcrop(gray, faceBBox);
            if isempty(faceROI)
                return;
            end

            % Eye detection inside face ROI
            obj.eyeDetector.UseROI = true;
            obj.eyeDetector.ROI = [1 1 size(faceROI,2) size(faceROI,1)];
            eyeBBoxesLocal = obj.eyeDetector.step(faceROI);
            obj.eyeDetector.UseROI = false;

            if isempty(eyeBBoxesLocal)
                return;
            end

            % Choose the widest eye pair region
            [~, idxEye] = max(eyeBBoxesLocal(:,3));
            eyeBBoxLocal = eyeBBoxesLocal(idxEye,:);

            % Convert local (face) coordinates to global
            eyeBBox = eyeBBoxLocal;
            eyeBBox(1) = eyeBBox(1) + faceBBox(1);
            eyeBBox(2) = eyeBBox(2) + faceBBox(2);

            % Crop eye region from the full gray frame (for better consistency)
            eyeROI = imcrop(gray, eyeBBox);
            if isempty(eyeROI)
                return;
            end

            % Compute eye-openness score
            eyeOpenScore = computeEyeOpenness(eyeROI);
        end

        function [isDrowsy, closedCount] = updateDrowsinessState(obj, eyeOpenScore)
            % updateDrowsinessState  Temporal logic for drowsiness detection.

            closedCount = obj.closedFrameCount;

            if isnan(eyeOpenScore)
                % No score (no face/eyes) -> do not update counters aggressively
                isDrowsy = obj.isDrowsy;
                return;
            end

            if eyeOpenScore < obj.cfg.eyeOpenThreshold
                closedCount = closedCount + 1;
            else
                closedCount = max(0, closedCount - 1);  % small hysteresis
            end

            isDrowsy = closedCount >= obj.cfg.closedFramesForDrowsy;

            % Update internal state
            obj.closedFrameCount = closedCount;
            obj.isDrowsy = isDrowsy;
        end

        function onKeyPress(obj, evt)
            % onKeyPress  Handle key press events on the figure.
            if isfield(evt, 'Key') && strcmpi(evt.Key, 'q')
                if ishghandle(obj.figHandle)
                    close(obj.figHandle);
                end
            end
        end
    end
end