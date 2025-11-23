# Drowsy Driver Detection using MATLAB

This project implements a **real-time drowsy driver detection** system in MATLAB using a **web camera**. The application monitors the driver’s eyes and raises an alert when prolonged eye closure (drowsiness) is detected.

The implementation is designed as a small, clean, educational project that you can extend with your own models or datasets.

---

## Features

- Real-time video acquisition from a webcam (or video file fallback)
- Face detection using Viola–Jones (MATLAB `vision.CascadeObjectDetector`)
- Eye region detection inside the face ROI
- Simple eye-openness score based on image statistics
- Temporal drowsiness logic: detects prolonged eye closure
- Visual overlay showing status (AWAKE / DROWSY) and eye score
- Configurable parameters via a single `config.m` file

---

## Project Structure

```text
.
├── README.md                # Project documentation
└── src
    ├── main.m               # Entry point
    ├── config.m             # Configuration and hyperparameters
    ├── DrowsinessDetector.m # Main detector class (capture + logic)
    ├── initDetectors.m      # Face / eye detector initialization
    ├── computeEyeOpenness.m # Eye openness scoring function
    └── drawStatusOverlay.m  # Visualization / HUD overlay
```

You can place additional utilities or models under `src/` if you extend the project.

---

## Requirements

- MATLAB (R2018b or newer recommended)
- Toolboxes:
  - Image Processing Toolbox
  - Computer Vision Toolbox
- A working webcam (for real-time detection)

The code also supports running on a **video file** (e.g., dashcam or recorded driver video) if a webcam is not available.

---

## Getting Started

1. **Clone / copy the repository** into a folder of your choice, for example:

   ```text
   drowsy-driver-detection-matlab/
   ```

2. Ensure the `src` folder is on the MATLAB path:

   ```matlab
   addpath(genpath('src'));
   ```

3. Open and review `src/config.m` to adjust:

   - Whether to use a webcam or video file
   - Eye-openness thresholds
   - Number of consecutive closed frames required to trigger drowsiness

4. Run the main script:

   ```matlab
   cd src
   main
   ```

5. Press `q` in the figure window to stop the detection loop.

---

## How It Works

1. **Frame acquisition**
   - From webcam using MATLAB’s `webcam` interface
   - Or from a video file using `VideoReader`

2. **Face detection**
   - Uses `vision.CascadeObjectDetector('FrontalFaceCART')`
   - If multiple faces are present, the largest bounding box is used.

3. **Eye region detection**
   - Uses a second cascade detector, e.g. `vision.CascadeObjectDetector('EyePairBig')`
   - The detected eye pair region is cropped from the face ROI.

4. **Eye-openness scoring**
   - The cropped eye region is converted to grayscale.
   - Contrast is enhanced and a threshold-based statistic is computed.
   - The resulting scalar "openness" score is compared to a threshold.

5. **Temporal drowsiness logic**
   - If the eye-openness score stays below a threshold for **N consecutive frames**, the driver is considered drowsy.
   - A visual red warning label (and optional `beep`) is shown.

---

## Configuration

All tunable parameters are centralized in `config.m`:

- `cfg.useWebcam` – `true` for webcam, `false` for video file
- `cfg.videoFile` – path to a video file when `useWebcam == false`
- `cfg.targetFps` – target frame rate for processing
- `cfg.eyeOpenThreshold` – threshold for eye-openness score
- `cfg.closedFramesForDrowsy` – number of consecutive closed-eye frames to trigger the drowsy state
- `cfg.maxRuntimeSeconds` – optional safety limit to stop after a certain duration

You are encouraged to tune these values for your camera, lighting conditions, and dataset.

---

## Notes on Datasets and Extensions

This project is designed to run **without a pre-downloaded dataset**, using your webcam in real time. However, you can:

- Replace the simple eye-openness heuristic with a trained classifier (SVM, CNN, etc.).
- Use offline datasets of driver faces and eye states to train a stronger model.
- Log frames and eye scores for later analysis or for building a labeled dataset.

---

## Usage Tips

- Ensure that your face and eyes are well lit.
- Try different distances from the camera.
- Adjust `eyeOpenThreshold` and `closedFramesForDrowsy` to avoid false positives/negatives.

---

## License

This project is provided under the **MIT License**. You can freely use, modify, and distribute it with appropriate attribution.
