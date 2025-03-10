# Image Background Remover - Flutter

A Flutter package that removes the background from images using an ONNX model. The package provides a seamless way to perform image processing, leveraging the power of machine learning through ONNX Runtime.

---

## 🌟 Features

- Remove the background from images with high accuracy.
- Works entirely offline, ensuring privacy and reliability.  
- Lightweight and optimized for efficient performance.  
- Simple and seamless integration with Flutter projects. 
- Add a custom background color to images.
- Customizable threshold value for better edge detection.

---

## 🔭 Overview
<img src="https://github.com/user-attachments/assets/a306cec8-82eb-482a-92d4-d5d99603aebc" alt="Overview" width="300" height="600" />


## Getting Started

### 🚀 Prerequisites

Before using this package, ensure that the following dependencies are included in your `pubspec.yaml`:

```yaml
dependencies:
  image_background_remover: ^latest_version
  ```

##  Usage
# Initialization
Before using the `removeBg` method, you must initialize the ONNX environment:
```dart
    import 'package:image_background_remover/image_background_remover.dart';

    @override
    void initState() {
        super.initState();
        BackgroundRemover.instance.initializeOrt();
    }
```


# Remove Background
To remove the background from an image:
``` dart
import 'dart:typed_data';
import 'package:image_background_remover/image_background_remover.dart';

Uint8List imageBytes = /* Load your image bytes */;
ui.Image resultImage = await BackgroundRemover.instance.removeBg(imageBytes);
/* resultImage will contain image with transparent background*/

```

## 🆕 New Feature: Add Background Color

You can now add a custom background color to images after removing the background.

### Usage:

```dart
Uint8List modifiedImage = await BackgroundRemover.instance.addBackground(
  image: originalImageBytes,
  bgColor: Colors.white, // Set your desired background color
);

```

## API

### Methods

| Method                          | Description                                                                 | Parameters                                      | Returns                           |
|---------------------------------|-----------------------------------------------------------------------------|------------------------------------------------|-----------------------------------|
| `initializeOrt()`               | Initializes the ONNX runtime environment. Call this method once before using `removeBg`. | None                                           | `Future<void>`                   |
| `removeBg(Uint8List imageBytes, { double threshold = 0.5, bool smoothMask = true, bool enhanceEdges = true })` | Removes the background from an image.                                     | `imageBytes` - The image in byte array format. <br><br> `threshold` - The confidence threshold for background removal (default: `0.5`). A higher value removes more background, while a lower value retains more foreground. <br><br> `smoothMask` - Whether to apply bilinear interpolation for smoother edges (default: `true`). <br><br> `enhanceEdges` - Whether to refine mask boundaries using gradient-based edge enhancement (default: `true`). | `Future<ui.Image>` - The processed image with the background removed. |
| `addBackground({required Uint8List image, required Color bgColor})` | Adds a background color to the given image. | `image` - The original image in byte array format. <br> `bgColor` - The background color to be applied. | `Future<Uint8List>` - The modified image with the background color applied. |


## ⛔️ iOS Issue
<details>
  <summary>Exception: ONNX session not initialized (iOS Release Mode & TestFlight)</summary>
  <br>

  To resolve this issue, update the following settings in Xcode:<br>

  Open Xcode and navigate to:<br>
  Runner.xcodeproj → Targets → Runner → Build Settings<br><br>

  Under the Deployment section:<br>
  Set "Strip Linked Product" to "No"<br>
  Set "Strip Style" to "Non-Global-Symbols"<br>

</details>


## ⚠️ Warning

This package uses an offline model to process images, which is bundled with the application. **This may increase the size of your app**. 


## 🔗 Contributing
Contributions are welcome! If you encounter any issues or have suggestions for improvements, feel free to create an issue or submit a pull request.

## ☕ Support This Project
If you find this package helpful and want to support its development, you can buy me a coffee! Your support helps maintain and improve this package. 😊

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-donate-orange?style=flat-square&logo=buy-me-a-coffee)](https://www.buymeacoffee.com/neteshpaudel)
