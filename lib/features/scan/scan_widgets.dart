import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
          title: const Text('Tomar foto'),
          onTap: () => Navigator.pop(context, ImageSource.camera),
        ),
        ListTile(
          key: ValueKey('$keyPrefix.gallery'),
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Elegir de la galería'),
          onTap: () => Navigator.pop(context, ImageSource.gallery),
        ),
      ],
    ),
  ),
);

/// Explains why the camera (or the photos) is needed, with "Abrir ajustes".
/// [purpose] completes "Lo usamos solo para …".
Future<void> explainPhotoPermission(
  BuildContext context, {
  required ImageSource source,
  required String keyPrefix,
  required String purpose,
  required Future<void> Function() openSettings,
}) async {
  final camera = source == ImageSource.camera;
  final alternative = camera
      ? 'Puedes activarla en los ajustes o elegir una foto de la galería.'
      : 'Puedes activarlo en los ajustes o tomar una foto con la cámara.';
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
            ? 'Permite el uso de la cámara'
            : 'Permite el acceso a tus fotos',
      ),
      content: Text('Lo usamos solo para $purpose $alternative'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Ahora no'),
        ),
        FilledButton(
          key: ValueKey('$keyPrefix.openSettings'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Abrir ajustes'),
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
        'Abre los ajustes del teléfono para permitirlo',
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
