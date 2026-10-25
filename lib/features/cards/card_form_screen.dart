import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/banks.dart';
import '../../core/clock.dart';
import '../../core/formatters.dart';
import '../../core/money.dart';
import '../../core/responsive.dart';
import '../../core/router.dart';
import '../../data/models/credit_card.dart';
import '../../services/card_scan_service.dart';
import '../../services/providers.dart';
import '../auth/auth_widgets.dart';
import '../scan/scan_widgets.dart';
import 'cards_providers.dart';

const defaultPaymentDays = 20;

/// Add a card ([cardId] null) or edit one. Only the last 4 digits are ever
/// asked for or stored.
class CardFormScreen extends ConsumerWidget {
  const CardFormScreen({super.key, this.cardId});

  final int? cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cardId == null) return const _CardForm(card: null);
    return switch (ref.watch(cardByIdProvider(cardId!))) {
      AsyncData(value: final card?) => _CardForm(card: card),
      AsyncData() || AsyncError() => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Tarjeta no encontrada')),
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _CardForm extends ConsumerStatefulWidget {
  const _CardForm({required this.card});

  final CreditCard? card;

  @override
  ConsumerState<_CardForm> createState() => _CardFormState();
}

class _CardFormState extends ConsumerState<_CardForm> {
  final _form = GlobalKey<FormState>();
  late final _alias = TextEditingController(text: widget.card?.alias);
  late final _bank = TextEditingController(text: widget.card?.bank);
  late final _last4 = TextEditingController(text: widget.card?.last4);
  late final _cutDay = TextEditingController(
    text: widget.card?.cutDay.toString(),
  );
  late final _paymentDays = TextEditingController(
    text: (widget.card?.paymentDays ?? defaultPaymentDays).toString(),
  );
  late final _limit = TextEditingController(
    text: switch (widget.card?.creditLimitCents) {
      null || 0 => '',
      final cents => centsToInput(cents),
    },
  );
  late final _limitUsd = TextEditingController(
    text: switch (widget.card?.secondaryLimitCents) {
      null || 0 => '',
      final cents => centsToInput(cents),
    },
  );
  late var _brand = widget.card?.brand ?? CardBrand.visa;
  late var _dual = widget.card?.dualCurrency ?? false;
  late var _currency =
      widget.card?.currency ??
      ref.read(currentUserProvider)?.defaultCurrency ??
      Currency.dop;
  late var _color = widget.card?.color ?? cardColors.first;
  var _saving = false;

  /// From choosing the source until the result: the button is disabled.
  var _scanBusy = false;

  /// Only while the photo is being read: the loading overlay.
  var _scanning = false;

  /// What the last scan filled in ('last4', 'brand', 'bank'). A field shows
  /// "Detectado por foto" while it still holds that value.
  var _detected = <String, Object>{};

  bool get _editing => widget.card != null;

  @override
  void initState() {
    super.initState();
    if (!_editing) {
      // A photo from a scan interrupted by Android must not stay on disk.
      unawaited(ref.read(cardScanServiceProvider).discardLostPhotos());
    }
    _last4.addListener(_onScannedFieldEdited);
    _bank.addListener(_onScannedFieldEdited);
  }

  void _onScannedFieldEdited() {
    if (_detected.isNotEmpty && mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _alias,
      _bank,
      _last4,
      _cutDay,
      _paymentDays,
      _limit,
      _limitUsd,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _scan() async {
    // Busy from the first tap, so a double tap cannot start two scans.
    if (_scanBusy) return;
    setState(() => _scanBusy = true);
    final source = await showPhotoSourceSheet(
      context,
      keyPrefix: 'cardForm.scan',
    );
    if (source == null || !mounted) {
      if (mounted) setState(() => _scanBusy = false);
      return;
    }
    final service = ref.read(cardScanServiceProvider);
    final CardScanResult result;
    try {
      result = await service.scan(
        source,
        onReading: () {
          if (mounted) setState(() => _scanning = true);
        },
      );
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedErrorMessage);
      return;
    } finally {
      if (mounted) {
        setState(() {
          _scanBusy = false;
          _scanning = false;
        });
      }
    }
    if (!mounted) return;
    switch (result) {
      case CardScanDetected(:final detection):
        setState(() {
          _detected = {
            'last4': ?detection.last4,
            'brand': ?detection.brand,
            'bank': ?detection.bank,
          };
          if (detection.last4 case final last4?) _last4.text = last4;
          if (detection.brand case final brand?) _brand = brand;
          if (detection.bank case final bank?) _bank.text = bank;
        });
      case CardScanNothing():
        showErrorSnackBar(
          context,
          'No pudimos leer la tarjeta, completa los datos manualmente',
        );
      case CardScanPermissionDenied(:final source):
        await explainPhotoPermission(
          context,
          source: source,
          keyPrefix: 'cardForm',
          purpose:
              'leer la tarjeta en tu teléfono. La foto no se guarda ni se '
              'envía, y solo conservamos los últimos 4 dígitos.',
          openSettings: service.openSettings,
        );
      case CardScanCancelled():
        break;
    }
  }

  bool _isDetected(String field, Object current) => _detected[field] == current;

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);
    final card = CreditCard(
      id: widget.card?.id,
      userId: user.id!,
      alias: _alias.text,
      bank: _bank.text,
      brand: _brand,
      last4: _last4.text,
      cutDay: int.parse(_cutDay.text),
      paymentDays: int.parse(_paymentDays.text),
      creditLimitCents: parseMoneyToCents(_limit.text) ?? 0,
      // A dual card keeps RD$ as its main currency and a US$ limit.
      currency: _dual ? Currency.dop : _currency,
      dualCurrency: _dual,
      secondaryLimitCents: _dual ? parseMoneyToCents(_limitUsd.text) ?? 0 : 0,
      color: _color,
      createdAt: widget.card?.createdAt ?? ref.read(clockProvider)(),
    );
    try {
      final repo = (await ref.read(reposProvider.future)).cards;
      if (_editing) {
        await repo.update(card);
      } else {
        await repo.create(card);
      }
      refreshFinance(ref);
      // true: saved (the setup wizard moves on).
      if (mounted) context.pop(true);
    } on ArgumentError catch (e) {
      // Business rule from the repository: show why.
      if (mounted) showErrorSnackBar(context, '${e.message}');
    } catch (_) {
      // StateError and I/O failures.
      if (mounted) showErrorSnackBar(context, unexpectedErrorMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Archivar esta tarjeta?'),
        content: const Text(
          'Dejará de aparecer en tus listas y en la recomendación. Sus datos '
          'se conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const ValueKey('cardForm.archiveConfirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final card = widget.card!;
    try {
      final repo = (await ref.read(reposProvider.future)).cards;
      await repo.archive(card.userId, card.id!);
      refreshFinance(ref);
      if (mounted) context.go(Routes.cards);
    } catch (_) {
      // Repository errors (StateError/ArgumentError) and I/O failures.
      if (mounted) showErrorSnackBar(context, unexpectedErrorMessage);
    }
  }

  String? _range(String? v, int min, int max, String message) {
    final n = int.tryParse(v?.trim() ?? '');
    return n == null || n < min || n > max ? message : null;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const gap = SizedBox(height: 14);

    return Scaffold(
      key: const ValueKey('cardForm.root'),
      appBar: AppBar(
        title: Text(_editing ? 'Editar tarjeta' : 'Nueva tarjeta'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ResponsiveCenter(
                maxWidth: ContentWidth.form,
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_editing) ...[
                        OutlinedButton.icon(
                          key: const ValueKey('cardForm.scan'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          onPressed: _scanBusy || _saving ? null : _scan,
                          icon: const Icon(Icons.document_scanner_outlined),
                          label: const Text('Escanear tarjeta'),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                          child: Text(
                            'Leemos la foto en tu teléfono y solo guardamos los '
                            'últimos 4 dígitos.',
                            style: text.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      TextFormField(
                        key: const ValueKey('cardForm.alias'),
                        controller: _alias,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Escribe un nombre para la tarjeta'
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Nombre (ej. Gastos del mes)',
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                      ),
                      gap,
                      _BankField(controller: _bank),
                      if (_isDetected('bank', _bank.text))
                        const FilledFromPhotoChip(
                          key: ValueKey('cardForm.detected.bank'),
                          label: 'Detectado por foto',
                          icon: Icons.photo_camera_outlined,
                        ),
                      gap,
                      Text('Marca', style: text.labelLarge),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final b in CardBrand.values)
                            ChoiceChip(
                              key: ValueKey('cardForm.brand.${b.name}'),
                              label: Text(b.label),
                              selected: _brand == b,
                              onSelected: (_) => setState(() => _brand = b),
                            ),
                        ],
                      ),
                      if (_isDetected('brand', _brand))
                        const FilledFromPhotoChip(
                          key: ValueKey('cardForm.detected.brand'),
                          label: 'Detectado por foto',
                          icon: Icons.photo_camera_outlined,
                        ),
                      gap,
                      TextFormField(
                        key: const ValueKey('cardForm.last4'),
                        controller: _last4,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) => RegExp(r'^\d{4}$').hasMatch(v ?? '')
                            ? null
                            : 'Escribe los últimos 4 dígitos',
                        decoration: const InputDecoration(
                          labelText: 'Últimos 4 dígitos',
                          prefixText: '•••• ',
                          prefixIcon: Icon(Icons.pin_outlined),
                          helperText: 'Nunca guardamos el número completo',
                        ),
                      ),
                      if (_isDetected('last4', _last4.text))
                        const FilledFromPhotoChip(
                          key: ValueKey('cardForm.detected.last4'),
                          label: 'Detectado por foto',
                          icon: Icons.photo_camera_outlined,
                        ),
                      gap,
                      TextFormField(
                        key: const ValueKey('cardForm.cutDay'),
                        controller: _cutDay,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) =>
                            _range(v, 1, 31, 'Escribe un día del 1 al 31'),
                        decoration: const InputDecoration(
                          labelText: 'Día de corte',
                          prefixIcon: Icon(Icons.event_outlined),
                          helperText:
                              'Si el mes es más corto, se usa el último día',
                        ),
                      ),
                      gap,
                      TextFormField(
                        key: const ValueKey('cardForm.paymentDays'),
                        controller: _paymentDays,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) =>
                            _range(v, 0, 60, 'Escribe de 0 a 60 días'),
                        decoration: const InputDecoration(
                          labelText: 'Días para pagar después del corte',
                          prefixIcon: Icon(Icons.hourglass_bottom),
                        ),
                      ),
                      gap,
                      Text('Moneda', style: text.labelLarge),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in Currency.values)
                            ChoiceChip(
                              key: ValueKey('cardForm.currency.${c.code}'),
                              label: Text('${c.symbol} ${c.code}'),
                              selected: !_dual && _currency == c,
                              onSelected: (_) => setState(() {
                                _currency = c;
                                _dual = false;
                              }),
                            ),
                          ChoiceChip(
                            key: const ValueKey('cardForm.currency.DUAL'),
                            label: const Text('RD\$ y US\$ (doble balance)'),
                            selected: _dual,
                            onSelected: (_) => setState(() {
                              _dual = true;
                              _currency = Currency.dop;
                            }),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 6),
                        child: Text(
                          _dual
                              ? 'Cada gasto queda en su moneda, con un límite por moneda.'
                              : 'Los gastos en otra moneda se convierten a esta.',
                          style: text.bodySmall,
                        ),
                      ),
                      gap,
                      TextFormField(
                        key: const ValueKey('cardForm.limit'),
                        controller: _limit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        // Empty = no limit registered; a typed limit must be > 0.
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return null;
                          final cents = parseMoneyToCents(v!);
                          return cents != null && cents > 0
                              ? null
                              : 'Monto no válido (ej. 50000 o 50,000.00)';
                        },
                        decoration: InputDecoration(
                          labelText: _dual
                              ? 'Límite en RD\$ (opcional)'
                              : 'Límite de crédito (opcional)',
                          prefixText: '${_currency.symbol} ',
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                        ),
                      ),
                      if (_dual) ...[
                        gap,
                        TextFormField(
                          key: const ValueKey('cardForm.limitUsd'),
                          controller: _limitUsd,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            if ((v ?? '').trim().isEmpty) return null;
                            final cents = parseMoneyToCents(v!);
                            return cents != null && cents > 0
                                ? null
                                : 'Monto no válido (ej. 50000 o 50,000.00)';
                          },
                          decoration: const InputDecoration(
                            labelText: 'Límite en US\$ (opcional)',
                            prefixText: 'US\$ ',
                            prefixIcon: Icon(Icons.account_balance_wallet),
                          ),
                        ),
                      ],
                      gap,
                      Text('Color', style: text.labelLarge),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final (i, c) in cardColors.indexed)
                            _ColorDot(
                              key: ValueKey('cardForm.color.$i'),
                              color: Color(c),
                              selected: _color == c,
                              onTap: () => setState(() => _color = c),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      LoadingButton(
                        key: const ValueKey('cardForm.save'),
                        label: _editing ? 'Guardar cambios' : 'Agregar tarjeta',
                        loading: _saving,
                        onPressed: _save,
                      ),
                      if (_editing) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const ValueKey('cardForm.archive'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .error,
                          ),
                          onPressed: _saving ? null : _archive,
                          icon: const Icon(Icons.archive_outlined),
                          label: const Text('Archivar tarjeta'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_scanning)
            const PhotoReadingOverlay(
              key: ValueKey('cardForm.scanning'),
              message: 'Leyendo la tarjeta…',
            ),
        ],
      ),
    );
  }
}

/// Bank name with suggestions from [dominicanBanks]; free text allowed.
class _BankField extends StatefulWidget {
  const _BankField({required this.controller});

  final TextEditingController controller;

  @override
  State<_BankField> createState() => _BankFieldState();
}

class _BankFieldState extends State<_BankField> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focus,
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return const [];
        return dominicanBanks.where((b) => b.toLowerCase().contains(q));
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
          TextFormField(
            key: const ValueKey('cardForm.bank'),
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Escribe el banco' : null,
            decoration: const InputDecoration(
              labelText: 'Banco',
              prefixIcon: Icon(Icons.account_balance),
            ),
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 400),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final o in options)
                  ListTile(
                    key: ValueKey('cardForm.bankOption.$o'),
                    title: Text(o),
                    onTap: () => onSelected(o),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }
}
