import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/l10n.dart';
import '../auth/auth_widgets.dart';

/// Shared UI for filling a form from a photo (card scan, receipt scan).
/// Keys are `<keyPrefix>.camera`, `<keyPrefix>.gallery`, and so on.

/// "Tomar foto" / "Elegir de la galería"; null when closed.
Future<ImageSource?> showPhotoSourceSheet(
  BuildContext context, {
  required String keyPrefix,
}) => showModalBottomSheet<ImageSource>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          key: ValueKey('$keyPrefix.camera'),
          leading: const Icon(Icons.photo_camera_outlined),
          title: Text(context.l10n.takePhoto),
          onTap: () => Navigator.pop(context, ImageSource.camera),
        ),
        ListTile(
          key: ValueKey('$keyPrefix.gallery'),
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(context.l10n.pickFromGallery),
          onTap: () => Navigator.pop(context, ImageSource.gallery),
        ),
      ],
    ),
  ),
);

/// Explains why the camera (or the photos) is needed, with "Abrir ajustes".
/// [purpose] is the full sentence saying what the photo is used for, in
/// the active language.
Future<void> explainPhotoPermission(
  BuildContext context, {
  required ImageSource source,
  required String keyPrefix,
  required String purpose,
  required Future<void> Function() openSettings,
}) async {
  final camera = source == ImageSource.camera;
  final alternative = camera
      ? context.l10n.permissionAltGallery
      : context.l10n.permissionAltCamera;
  final open = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: ValueKey('$keyPrefix.permissionDialog'),
      scrollable: true,
      icon: Icon(
        camera ? Icons.no_photography_outlined : Icons.hide_image_outlined,
      ),
      title: Text(
        camera
            ? context.l10n.allowCamera
            : context.l10n.allowPhotos,
      ),
      content: Text('$purpose $alternative'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.notNow),
        ),
        FilledButton(
          key: ValueKey('$keyPrefix.openSettings'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.l10n.openSettings),
        ),
      ],
    ),
  );
  if (open != true) return;
  try {
    await openSettings();
  } catch (_) {
    // No settings channel on this platform.
    if (context.mounted) {
      showErrorSnackBar(
        context,
        context.l10n.openSettingsHint,
      );
    }
  }
}

/// Marks a field filled in from a photo while it keeps that value.
class FilledFromPhotoChip extends StatelessWidget {
  const FilledFromPhotoChip({
    super.key,
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Chip(
          avatar: Icon(icon, size: 18),
          label: Text(label),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

/// Covers the form while a photo is read. Goes in a `Stack`.
class PhotoReadingOverlay extends StatelessWidget {
  const PhotoReadingOverlay({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
