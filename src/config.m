function cfg = config()
% config  Central configuration for the drowsy driver detection system.
%
%   Returns a struct `cfg` containing all configurable parameters.

    % ---- Data source configuration ----
    cfg.useWebcam   = true;               % true: webcam, false: video file
    cfg.webcamIndex = 1;                  % index of the webcam (1 = default)
    cfg.videoFile   = 'sample_driver.mp4';% used if useWebcam == false

    % Target frame size for processing (scales input frames)
    cfg.targetFrameWidth  = 640;
    cfg.targetFrameHeight = 360;

    % Approximate processing frame rate cap (Hz)
    cfg.targetFps = 15;

    % ---- Drowsiness logic parameters ----
    % Eye-openness score threshold: lower => more sensitive to closure
    cfg.eyeOpenThreshold = 0.18;

    % Number of consecutive frames with closed eyes required to declare drowsiness
    cfg.closedFramesForDrowsy = 15;  % with 15 fps ~ 1 second

    % Optional hard stop after N seconds (0 = disabled)
    cfg.maxRuntimeSeconds = 0;

    % Enable or disable audio alert
    cfg.enableBeep = true;

    % Visualization options
    cfg.showEyeScore = true;
    cfg.showFrameRate = true;

    % Detector tuning
    cfg.faceDetectorMergeThreshold = 4;
    cfg.eyeDetectorMergeThreshold  = 2;

    % Random seed for reproducibility where applicable
    rng(0);
end