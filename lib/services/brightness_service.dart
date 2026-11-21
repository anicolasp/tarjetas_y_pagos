import 'package:screen_brightness/screen_brightness.dart';

/// The app window's own brightness (#39). Only ever changes this app's
/// window; the phone's brightness setting is never touched.
abstract interface class BrightnessService {
  /// The phone's current brightness (0–1), or null when unknown.
  Future<double?> system();

  /// Shows the app at [value] (0–1) while it is in the foreground.
  Future<void> apply(double value);

  /// Back to the phone's brightness.
  Future<void> reset();
}

class PluginBrightnessService implements BrightnessService {
  ScreenBrightness get _plugin => ScreenBrightness.instance;

  // Brightness is a comfort setting: a platform without it, or a plugin
  // error, leaves the screen as it is instead of breaking the app.

  @override
  Future<double?> system() async {
    try {
      return await _plugin.system;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> apply(double value) async {
    try {
      await _plugin.setApplicationScreenBrightness(value);
    } on Object {
      // See above.
    }
  }

  @override
  Future<void> reset() async {
    try {
      await _plugin.resetApplicationScreenBrightness();
    } on Object {
      // See above.
    }
  }
}
