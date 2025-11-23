function main()
% main  Entry point for Drowsy Driver Detection using MATLAB.
%
%   This script initializes configuration, the drowsiness detector
%   object, and starts the main processing loop.
%
%   Press 'q' in the figure window to stop the detection.
%
%   Author: Mobin Yousefi (GitHub: github.com/mobinyousefi-cs)

    clc;
    close all;

    % Add src folder to path if user runs from project root
    if ~contains(path, fullfile(pwd))
        addpath(genpath(pwd)); %#ok<MCAP>
    end

    % Load configuration
    cfg = config();

    % Create detector instance
    detector = DrowsinessDetector(cfg);

    % Run and ensure cleanup
    try
        detector.run();
    catch ME
        fprintf(2, '\n[ERROR] %s\n', ME.message);
    end

    % Explicitly delete object to release webcam/video resources
    delete(detector);
end