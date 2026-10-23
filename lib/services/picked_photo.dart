/// Photos taken or chosen with `image_picker` live only while they are read:
/// every copy the plugin makes is deleted afterwards.
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Implemented in `MainActivity.kt`.
const _settings = MethodChannel('tarjetas_y_pagos/settings');

/// Opens this app's system settings (to grant the camera or the photos).
/// Throws where the platform has no such channel.
Future<void> openAppSettings() =>
    _settings.invokeMethod<void>('openAppSettings');

/// The user denied the camera or the photos.
bool isPhotoPermissionDenied(PlatformException e) =>
    e.code == 'camera_access_denied' || e.code == 'photo_access_denied';

/// Photos left behind when Android closed the app while the camera or the
/// gallery was open. Android only; elsewhere there is nothing lost.
Future<List<String>> lostPickedPhotos() async {
  if (!Platform.isAndroid) return const [];
  final lost = await ImagePicker().retrieveLostData();
  return [for (final f in lost.files ?? const <XFile>[]) f.path];
}

/// Deletes the photos [lost] returns. Best effort, never throws.
Future<void> discardLostPickedPhotos(
  Future<List<String>> Function() lost,
) async {
  try {
    for (final path in await lost()) {
      await deletePickedPhoto(path);
    }
  } on Exception {
    // Nothing to recover from.
  }
}

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

const _scaledPrefix = 'scaled_';

/// Deletes a picked photo and the copies image_picker made of it: a gallery
/// photo is copied into its own `cache/<uuid>/` folder, and a resized one
/// is written next to it as `cache/scaled_<name>` while that copy stays.
Future<void> deletePickedPhoto(String path) async {
  final photo = File(path);
  final name = photo.uri.pathSegments.last;
  await _deleteFileAndUuidFolder(photo);
  if (!name.startsWith(_scaledPrefix)) return;
  final original = name.substring(_scaledPrefix.length);
  try {
    await for (final entry in photo.parent.list()) {
      if (entry is Directory && _uuid.hasMatch(_lastSegment(entry))) {
        await _deleteFileAndUuidFolder(File('${entry.path}/$original'));
      }
    }
  } on FileSystemException {
    // The cache folder is gone too.
  }
}

String _lastSegment(FileSystemEntity e) =>
    e.uri.pathSegments.lastWhere((s) => s.isNotEmpty);

Future<void> _deleteFileAndUuidFolder(File file) async {
  try {
    if (await file.exists()) await file.delete();
    final folder = file.parent;
    if (_uuid.hasMatch(_lastSegment(folder)) && await folder.list().isEmpty) {
      await folder.delete();
    }
  } on FileSystemException {
    // Already gone.
  }
}
