import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/responsive.dart';
import '../../services/providers.dart';

class _Slide {
  const _Slide(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

const _slides = [
  _Slide(
    Icons.credit_card,
    'Tus tarjetas',
    'Registra tus tarjetas de crédito con una foto. Solo guardamos los '
        'últimos 4 dígitos.',
  ),
  _Slide(
    Icons.receipt_long,
    'Gastos con IA',
    'Toma una foto de la factura y la app llena el gasto por ti.',
  ),
  _Slide(
    Icons.event_available,
    'Mejor tarjeta hoy',
    'Te decimos qué tarjeta usar según su fecha de corte para pagar más tarde.',
  ),
  _Slide(
    Icons.insights,
    'Reportes',
    'Filtra por fecha, tarjeta, categoría o comercio y mira en qué se va tu '
        'dinero.',
  ),
];

/// Welcome slides, shown only the first time the app opens.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  var _page = 0;

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() => ref.read(onboardingSeenProvider.notifier).complete();

  void _next() => _pages.nextPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: const ValueKey('onboarding.root'),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
                child: TextButton(
                  key: const ValueKey('onboarding.skip'),
                  onPressed: _finish,
                  child: const Text('Omitir'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _SlideView(_slides[i]),
              ),
            ),
            ResponsiveCenter(
              maxWidth: ContentWidth.form,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                // Dots above a full-width button: never overflows, even with
                // large text on a narrow phone.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _slides.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _page ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: ValueKey(
                        _isLast ? 'onboarding.start' : 'onboarding.next',
                      ),
                      onPressed: _isLast ? _finish : _next,
                      child: Text(_isLast ? 'Empezar' : 'Siguiente'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView(this.slide);

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final iconSize = context.isCompact ? 112.0 : 136.0;

    return CenteredScrollView(
      child: ResponsiveCenter(
        maxWidth: ContentWidth.form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                slide.icon,
                size: iconSize * 0.5,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              slide.body,
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
