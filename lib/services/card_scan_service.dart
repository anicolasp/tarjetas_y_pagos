import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../core/card_detection.dart';
import 'picked_photo.dart';

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

/// Access to the camera (or to the photos) was denied.
class CardScanPermissionDenied extends CardScanResult {
  const CardScanPermissionDenied(this.source);

  final ImageSource source;
}

abstract interface class CardScanService {
  /// [onReading] runs once a photo was chosen, right before the OCR.
  Future<CardScanResult> scan(ImageSource source, {void Function()? onReading});

  /// Opens the system settings of the app (to grant the camera). Throws
  /// when the platform cannot open them.
  Future<void> openSettings();

  /// Deletes photos left behind when Android closed the app while the
  /// camera or the gallery was open (they are never read).
  Future<void> discardLostPhotos();
}

/// Photo with `image_picker`, text with ML Kit on the device. The photo is
/// deleted after reading it and the OCR text is never logged.
class MlKitCardScanService implements CardScanService {
  MlKitCardScanService({
    Future<String?> Function(ImageSource source)? pick,
    Future<String> Function(String path)? recognize,
    Future<List<String>> Function()? lostPhotos,
  }) : _pick = pick ?? _pickWithImagePicker,
       _recognize = recognize ?? _recognizeWithMlKit,
       _lostPhotos = lostPhotos ?? lostPickedPhotos;

  final Future<String?> Function(ImageSource source) _pick;
  final Future<String> Function(String path) _recognize;
  final Future<List<String>> Function() _lostPhotos;

  /// No resizing on purpose: a scaled copy would leave the picker's
  /// original copy of a gallery photo behind in the cache.
  static Future<String?> _pickWithImagePicker(ImageSource source) async =>
      (await ImagePicker().pickImage(
        source: source,
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
  Future<CardScanResult> scan(
    ImageSource source, {
    void Function()? onReading,
  }) async {
    await discardLostPhotos();
    final String? path;
    try {
      path = await _pick(source);
    } on PlatformException catch (e) {
      if (isPhotoPermissionDenied(e)) return CardScanPermissionDenied(source);
      rethrow;
    }
    if (path == null) return const CardScanCancelled();
    try {
      onReading?.call();
      final detection = detectCard(await _recognize(path));
      return detection.isEmpty
          ? const CardScanNothing()
          : CardScanDetected(detection);
    } finally {
      await deletePickedPhoto(path);
    }
  }

  @override
  Future<void> discardLostPhotos() => discardLostPickedPhotos(_lostPhotos);

  @override
  Future<void> openSettings() => openAppSettings();
}
