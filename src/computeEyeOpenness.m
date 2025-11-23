function score = computeEyeOpenness(eyeROI)
% computeEyeOpenness  Compute a simple eye-openness score from eye ROI.
%
%   score = computeEyeOpenness(eyeROI)
%
%   Heuristic approach (no learned model):
%     1. Convert to double and normalize
%     2. Enhance contrast
%     3. Apply adaptive thresholding
%     4. Use ratio of bright pixels and edge density as proxy for openness
%
%   The output `score` is roughly in [0, 1]; lower values are more likely
%   to correspond to closed eyes. You should tune `eyeOpenThreshold` in
%   `config.m` for your own environment.

    if size(eyeROI,3) == 3
        eyeROI = rgb2gray(eyeROI);
    end

    eyeROI = im2double(eyeROI);

    % Contrast enhancement
    eyeEnhanced = adapthisteq(eyeROI, 'NumTiles', [4 2], 'ClipLimit', 0.01);

    % Adaptive threshold
    T = adaptthresh(eyeEnhanced, 0.4);  % 0.4 is a reasonable default
    bw = imbinarize(eyeEnhanced, T);

    % Morphological cleanup
    bw = bwareaopen(bw, 10);

    % Ratio of bright pixels
    brightRatio = nnz(bw) / numel(bw);

    % Edge-based feature
    edges = edge(eyeEnhanced, 'sobel');
    edgeRatio = nnz(edges) / numel(edges);

    % Combine heuristics: more edges and moderate bright ratio
    % We expect open eyes to have some white sclera and edges from eyelids/iris.
    combined = 0.5 * brightRatio + 0.5 * edgeRatio;

    % Normalize heuristically into [0,1]
    score = min(max(combined, 0), 1);
end