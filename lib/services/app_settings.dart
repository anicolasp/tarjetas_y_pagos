import 'package:flutter/services.dart';

/// Implemented in `MainActivity.kt`.
const _settings = MethodChannel('tarjetas_y_pagos/settings');

/// Opens this app's system settings (to grant the camera, the photos or
/// the notifications). Throws where the platform has no such channel.
Future<void> openAppSettings() =>
    _settings.invokeMethod<void>('openAppSettings');
