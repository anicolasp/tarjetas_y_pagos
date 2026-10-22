import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive.dart';
import '../../data/providers.dart';
import '../auth/auth_controller.dart';

/// Shown while the app opens the database and decides the initial route.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final db = ref.watch(appDatabaseProvider);
    final logoSize = context.isCompact ? 96.0 : 120.0;

    return Scaffold(
      key: const ValueKey('splash.root'),
      body: SafeArea(
        child: CenteredScrollView(
          child: ResponsiveCenter(
            maxWidth: ContentWidth.form,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(logoSize * 0.29),
                    ),
                    child: Icon(
                      Icons.credit_card,
                      size: logoSize * 0.54,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tarjetas y Pagos',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tus tarjetas, gastos y deudas en un solo lugar',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // While retrying, Riverpod keeps the previous error, so
                  // only show it once loading has finished.
                  if (db.hasError && !db.isLoading) ...[
                    Text(
                      'No se pudo abrir la base de datos',
                      key: const ValueKey('splash.error'),
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: scheme.error),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: const ValueKey('splash.retry'),
                      onPressed: () => ref
                        ..invalidate(appDatabaseProvider)
                        // Restores the session once the database opens.
                        ..invalidate(authControllerProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ] else
                    const SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(
                        key: ValueKey('splash.loading'),
                        strokeWidth: 3,
                      ),
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
