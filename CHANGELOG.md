## 0.0.7

### Added
- Implemented threshold-based segmentation to refine background removal.
- Integrated a smooth edge method using bilinear interpolation and average neighboring to improve output quality  and reduce harsh edges.
- Implemented edge enhancement for mask refinement using a Sobel-like gradient detection method.

## 0.0.6

### Feat
- Added `addBackground` function to change background of color

## 0.0.5

### Fix
- Minor bug fixes

## 0.0.4

### Fix
- Solved ONNX session creation error

## 0.0.3

### Added
- Added assets file.

## 0.0.2

### Fix
- Removed incompatible platform support.

## 0.0.1

### Added
- Initial release of the **Background Remover Service** Flutter package.
- ONNX Runtime integration for background removal using the `onnx` model.
- Functions to initialize ONNX session:
  - `initializeOrt()`: Initialize the ONNX environment and session.
- Image processing capabilities:
  - `removeBg(Uint8List imageBytes)`: Removes the background from an input image and returns the image with a transparent background.
  - `_resizeImage()`: Resizes an image to 320x320 for ONNXy model compatibility.
  - `_imageToFloatTensor()`: Converts RGBA image data into a normalized float tensor for model input.
  - `_applyMaskToOriginalSizeImage()`: Applies the generated mask back to the original image size.
- Utility methods:
  - `resizeMask()`: Resizes the ONNX output mask to match the original image dimensions.
- Designed for cross-platform support (iOS, Android, Web, and Desktop).
