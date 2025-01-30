import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_background_remover/assets.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;

class BackgroundRemover {
  BackgroundRemover._internal();

  static final BackgroundRemover _instance = BackgroundRemover._internal();

  static BackgroundRemover get instance => _instance;

  // The ONNX session used for inference.
  OrtSession? _session;

  /// Initializes the ONNX environment and creates a session.
  ///
  /// This method should be called once before using the [removeBg] method.
  Future<void> initializeOrt() async {
    try {
      /// Initialize the ONNX runtime environment.
      OrtEnv.instance.init();

      /// Create the ONNX session.
      await _createSession();
    } catch (e) {
      log(e.toString());
    }
  }

  /// Creates an ONNX session using the model from assets.
  Future<void> _createSession() async {
    try {
      /// Session configuration options.
      final sessionOptions = OrtSessionOptions();

      /// Load the model as a raw asset.
      final rawAssetFile = await rootBundle.load(Assets.modelPath);

      /// Convert the asset to a byte array.
      final bytes = rawAssetFile.buffer.asUint8List();

      /// Create the ONNX session.
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
      if (kDebugMode) {
        log('ONNX session created successfully.', name: "BackgroundRemover");
      }
    } catch (e) {
      if (kDebugMode) {
        log('Error creating ONNX session: $e', name: "BackgroundRemover");
      }
    }
  }

  /// Removes the background from an image.
  ///
  /// This function processes the input image and removes its background,
  /// returning a new image with the background removed.
  ///
  /// - [imageBytes]: The input image as a byte array.
  /// - Returns: A [ui.Image] with the background removed.
  ///
  /// Example usage:
  /// ```dart
  /// final imageBytes = await File('path_to_image').readAsBytes();
  /// final ui.Image imageWithoutBackground = await removeBackground(imageBytes);
  /// ```
  ///
  /// Note: This function may take some time to process depending on the size
  /// and complexity of the input image.
  Future<ui.Image> removeBg(Uint8List imageBytes) async {
    if (_session == null) {
      throw Exception("ONNX session not initialized");
    }

    /// Decode the input image and resize it to the required dimensions.
    final originalImage = await decodeImageFromList(imageBytes);
    log('Original image size: ${originalImage.width}x${originalImage.height}');
    final resizedImage = await _resizeImage(originalImage, 320, 320);

    /// Convert the resized image into a tensor format required by the ONNX model.
    final rgbFloats = await _imageToFloatTensor(resizedImage);
    final inputTensor = OrtValueTensor.createTensorWithDataList(
      Float32List.fromList(rgbFloats),
      [1, 3, 320, 320],
    );

    /// Prepare the inputs and run inference on the ONNX model.
    final inputs = {'input.1': inputTensor};
    final runOptions = OrtRunOptions();
    final outputs = await _session!.runAsync(runOptions, inputs);
    inputTensor.release();
    runOptions.release();

    /// Process the output tensor and generate the final image with the background removed.
    final outputTensor = outputs?[0]?.value;
    if (outputTensor is List) {
      final mask = outputTensor[0][0];
      final resizedMask =
          resizeMask(mask, originalImage.width, originalImage.height);
      return _applyMaskToOriginalSizeImage(originalImage, resizedMask);
    } else {
      throw Exception('Unexpected output format from ONNX model.');
    }
  }

  /// Resizes the input image to the specified dimensions.
  Future<ui.Image> _resizeImage(
      ui.Image image, int targetWidth, int targetHeight) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    final srcRect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect =
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble());
    canvas.drawImageRect(image, srcRect, dstRect, paint);

    final picture = recorder.endRecording();
    return picture.toImage(targetWidth, targetHeight);
  }

  /// Resizes the mask to match the original image dimensions.
  List resizeMask(List mask, int originalWidth, int originalHeight) {
    final resizedMask = List.generate(
      originalHeight,
      (_) => List.filled(originalWidth, 0.0),
    );

    for (int y = 0; y < originalHeight; y++) {
      for (int x = 0; x < originalWidth; x++) {
        final scaledX = x * 320 ~/ originalWidth;
        final scaledY = y * 320 ~/ originalHeight;
        resizedMask[y][x] = mask[scaledY][scaledX];
      }
    }
    return resizedMask;
  }

  /// Converts an image into a floating-point tensor.
  Future<List<double>> _imageToFloatTensor(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to get image ByteData");
    final rgbaBytes = byteData.buffer.asUint8List();
    final pixelCount = image.width * image.height;
    final floats = List<double>.filled(pixelCount * 3, 0);

    /// Extract and normalize RGB channels.
    for (int i = 0; i < pixelCount; i++) {
      floats[i] = rgbaBytes[i * 4] / 255.0; // Red
      floats[pixelCount + i] = rgbaBytes[i * 4 + 1] / 255.0; // Green
      floats[2 * pixelCount + i] = rgbaBytes[i * 4 + 2] / 255.0; // Blue
    }
    return floats;
  }

  /// Applies the mask to the original image and generates the final output.
  ///
  /// This method takes the mask generated by the background removal algorithm
  /// and applies it to the original image to produce the final image with the
  /// background removed. The resulting image will have the background pixels
  /// replaced with transparency or a specified color.
  ///
  /// Returns:
  ///   A new image with the background removed.
  Future<ui.Image> _applyMaskToOriginalSizeImage(
      ui.Image image, List resizedMask) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to get image ByteData");

    final rgbaBytes = byteData.buffer.asUint8List();
    final pixelCount = image.width * image.height;
    final outRgbaBytes = Uint8List(4 * pixelCount);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final i = y * image.width + x;
        final maskValue = (resizedMask[y][x] * 255).clamp(0, 255).toInt();

        outRgbaBytes[i * 4] = rgbaBytes[i * 4]; // Red
        outRgbaBytes[i * 4 + 1] = rgbaBytes[i * 4 + 1]; // Green
        outRgbaBytes[i * 4 + 2] = rgbaBytes[i * 4 + 2]; // Blue
        outRgbaBytes[i * 4 + 3] = maskValue; // Alpha
      }
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        outRgbaBytes, image.width, image.height, ui.PixelFormat.rgba8888,
        (ui.Image img) {
      completer.complete(img);
    });

    return completer.future;
  }

  /// Adds a background color to the given image.
  ///
  /// This method takes an image in the form of a [Uint8List] and a background
  /// color as a [Color]. It decodes the image, creates a new image with the
  /// same dimensions, fills it with the specified background color, and then
  /// composites the original image onto the new image with the background color.
  ///
  /// Returns a [Future] that completes with the modified image as a [Uint8List].
  ///
  /// - Parameters:
  ///   - image: The original image as a [Uint8List].
  ///   - bgColor: The background color as a [Color].
  ///
  /// - Returns: A [Future] that completes with the modified image as a [Uint8List].
  Future<Uint8List> addBackground(
      {required Uint8List image, required Color bgColor}) async {
    final img.Image decodedImage = img.decodeImage(image)!;
    final newImage =
        img.Image(width: decodedImage.width, height: decodedImage.height);
    img.fill(newImage,
        color: img.ColorRgb8(bgColor.red, bgColor.green, bgColor.blue));
    img.compositeImage(newImage, decodedImage);
    final jpegBytes = img.encodeJpg(newImage);
    final completer = Completer<Uint8List>();
    completer.complete(jpegBytes.buffer.asUint8List());
    return completer.future;
  }
}
