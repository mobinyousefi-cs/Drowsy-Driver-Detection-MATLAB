function [faceDetector, eyeDetector] = initDetectors(cfg)
% initDetectors  Initialize Viola-Jones face and eye detectors.
%
%   [faceDetector, eyeDetector] = initDetectors(cfg)
%
%   Uses MATLAB's vision.CascadeObjectDetector with predefined models.

    % Face detector
    faceDetector = vision.CascadeObjectDetector('FrontalFaceCART', ...
        'MergeThreshold', cfg.faceDetectorMergeThreshold);

    % Eye detector (eye pair)
    % Alternatives include 'RightEye', 'LeftEye', etc.
    eyeDetector = vision.CascadeObjectDetector('EyePairBig', ...
        'MergeThreshold', cfg.eyeDetectorMergeThreshold);
end