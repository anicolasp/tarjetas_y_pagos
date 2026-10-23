import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../core/card_detection.dart';

export 'package:image_picker/image_picker.dart' show ImageSource;

sealed class CardScanResult {
  const CardScanResult();
}

/// At least one field was read. Only last 4, brand and bank.
class CardScanDetected extends CardScanResult {
  const CardScanDetected(this.detection);

  final CardDetection detection;
}

/// The photo had nothing usable.
class CardScanNothing extends CardScanResult {
  const CardScanNothing();
}

/// The user closed the camera or the gallery without choosing.
class CardScanCancelled extends CardScanResult {
  const CardScanCancelled();
}

/// Camera permission was denied.
class CardScanPermissionDenied extends CardScanResult {
  const CardScanPermissionDenied();
}

abstract interface class CardScanService {
  Future<CardScanResult> scan(ImageSource source);

  /// Opens the system settings of the app (to grant the camera).
  Future<void> openSettings();
}

/// Photo with `image_picker`, text with ML Kit on the device. The photo is
/// deleted after reading it and the OCR text is never logged.
class MlKitCardScanService implements CardScanService {
  MlKitCardScanService({
    Future<String?> Function(ImageSource source)? pick,
    Future<String> Function(String path)? recognize,
  }) : _pick = pick ?? _pickWithImagePicker,
       _recognize = recognize ?? _recognizeWithMlKit;

  final Future<String?> Function(ImageSource source) _pick;
  final Future<String> Function(String path) _recognize;

  static Future<String?> _pickWithImagePicker(ImageSource source) async =>
      (await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        requestFullMetadata: false,
      ))?.path;

  static Future<String> _recognizeWithMlKit(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return (await recognizer.processImage(InputImage.fromFilePath(path)))
          .text;
    } finally {
      await recognizer.close();
    }
  }

  @override
  Future<CardScanResult> scan(ImageSource source) async {
    final String? path;
    try {
      path = await _pick(source);
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied' || e.code == 'photo_access_denied') {
        return const CardScanPermissionDenied();
      }
      rethrow;
    }
    if (path == null) return const CardScanCancelled();
    try {
      final detection = detectCard(await _recognize(path));
      return detection.isEmpty
          ? const CardScanNothing()
          : CardScanDetected(detection);
    } finally {
      try {
        await File(path).delete();
      } on FileSystemException {
        // Already gone.
      }
    }
  }

  @override
  Future<void> openSettings() => AppSettings.openAppSettings();
}
