import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/category_icons.dart';
import '../../core/responsive.dart';
import '../../data/models/category.dart';
import '../../data/repositories/categories_repository.dart';
import '../auth/auth_widgets.dart';
import '../cards/cards_providers.dart';
import '../reports/chart_colors.dart';

/// New category ([categoryId] null) or edit/delete an own one: name, icon
/// and color.
class CategoryFormScreen extends ConsumerWidget {
  const CategoryFormScreen({super.key, this.categoryId});

  final int? categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryId == null) return const _CategoryForm(category: null);
    final categories = ref.watch(categoriesProvider);
    if (!categories.hasValue) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: categories.hasError
              ? const Text(
                  'No se pudieron cargar las categorías',
                  key: ValueKey('categoryForm.loadError'),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }
    final own = categories.value!.where((c) => c.id == categoryId && !c.isBase);
    if (own.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Categoría no encontrada')),
      );
    }
    return _CategoryForm(category: own.single);
  }
}

class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm({required this.category});

  final Category? category;

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name);
  late var _icon = widget.category?.icon ?? 'pets';
  late var _color = widget.category?.color ?? categoryColors.first;
  var _saving = false;

  bool get _editing => widget.category != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);
    final c = Category(
      id: widget.category?.id,
      userId: user.id,
      name: _name.text,
      icon: _icon,
      color: _color,
    );
    try {
      final repo = (await ref.read(reposProvider.future)).categories;
      if (_editing) {
        await repo.update(user.id!, c);
      } else {
        await repo.create(user.id!, c);
      }
      refreshCategories(ref);
      if (mounted) context.pop();
    } on ArgumentError catch (e) {
      if (mounted) showErrorSnackBar(context, '${e.message}');
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedErrorMessage);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Without expenses: a plain confirmation. With expenses: pick where
  /// they go ("Otros" first), then delete in one go.
  Future<void> _delete() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final c = widget.category!;
    try {
      final repo = (await ref.read(reposProvider.future)).categories;
      final count = await repo.expenseCount(user.id!, c.id!);
      if (!mounted) return;
      // Once the list reloads this page shows "no encontrada" and this
      // State goes away, so take the router now.
      final router = GoRouter.of(context);
      int? target;
      if (count == 0) {
        final ok = await confirmDestructive(
          context,
          title: '¿Eliminar "${c.name}"?',
          body: 'No tiene gastos.',
          confirmKey: const ValueKey('categoryForm.deleteConfirm'),
        );
        if (!ok) return;
      } else {
        // Already alphabetical with "Otros" last: bring "Otros" first.
        final rest = [
          for (final o in ref.read(categoriesProvider).value ?? <Category>[])
            if (o.id != c.id) o,
        ];
        final others = [
          ...rest.where((o) => o.name == 'Otros'),
          ...rest.where((o) => o.name != 'Otros'),
        ];
        target = await showDialog<int>(
          context: context,
          builder: (context) =>
              _ReassignDialog(name: c.name, count: count, options: others),
        );
        if (target == null) return;
      }
      await repo.delete(user.id!, c.id!, reassignTo: target);
      refreshCategories(ref);
      router.pop();
    } on CategoryInUseException {
      // Expenses were added meanwhile: ask again.
      if (mounted) _delete();
    } catch (_) {
      if (mounted) showErrorSnackBar(context, unexpectedErrorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    const gap = SizedBox(height: 16);

    return Scaffold(
      key: const ValueKey('categoryForm.root'),
      appBar: AppBar(
        title: Text(_editing ? 'Editar categoría' : 'Nueva categoría'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ResponsiveCenter(
            maxWidth: ContentWidth.form,
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const ValueKey('categoryForm.name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: categoryNameMaxLength,
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Escribe un nombre' : null,
                    decoration: InputDecoration(
                      labelText: 'Nombre (ej. Mascotas)',
                      prefixIcon: Icon(
                        categoryIcon(_icon),
                        color: readableOn(
                          Color(_color),
                          scheme.surfaceContainerHighest,
                        ),
                      ),
                      counterText: '',
                    ),
                  ),
                  gap,
                  Text('Ícono', style: text.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final MapEntry(key: k, value: icon)
                          in categoryIcons.entries)
                        ChoiceChip(
                          key: ValueKey('categoryForm.icon.$k'),
                          showCheckmark: false,
                          label: Icon(icon, size: 22),
                          selected: _icon == k,
                          tooltip: k,
                          onSelected: (_) => setState(() => _icon = k),
                        ),
                    ],
                  ),
                  gap,
                  Text('Color', style: text.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final (i, c) in categoryColors.indexed)
                        Semantics(
                          button: true,
                          selected: _color == c,
                          label: 'Color ${i + 1}',
                          child: InkResponse(
                            key: ValueKey('categoryForm.color.$i'),
                            onTap: () => setState(() => _color = c),
                            radius: 26,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(c),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _color == c
                                      ? scheme.onSurface
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: _color == c
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  LoadingButton(
                    key: const ValueKey('categoryForm.save'),
                    label: _editing ? 'Guardar cambios' : 'Crear categoría',
                    loading: _saving,
                    onPressed: _save,
                  ),
                  if (_editing) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const ValueKey('categoryForm.delete'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        foregroundColor: scheme.error,
                      ),
                      onPressed: _saving ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar categoría'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Tiene N gastos: ¿a qué categoría los movemos?" Returns the chosen id.
class _ReassignDialog extends StatefulWidget {
  const _ReassignDialog({
    required this.name,
    required this.count,
    required this.options,
  });

  final String name;
  final int count;
  final List<Category> options;

  @override
  State<_ReassignDialog> createState() => _ReassignDialogState();
}

class _ReassignDialogState extends State<_ReassignDialog> {
  late int _target = widget.options.first.id!;

  @override
  Widget build(BuildContext context) {
    final n = widget.count;
    return AlertDialog(
      key: const ValueKey('categoryForm.reassignDialog'),
      scrollable: true,
      title: Text('"${widget.name}" tiene $n ${n == 1 ? 'gasto' : 'gastos'}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Para eliminarla, elige a qué categoría pasan.'),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: const ValueKey('categoryForm.reassignTo'),
            initialValue: _target,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Pasar a'),
            items: [
              for (final c in widget.options)
                DropdownMenuItem(
                  value: c.id,
                  child: Row(
                    children: [
                      Icon(
                        categoryIcon(c.icon),
                        size: 18,
                        color: readableOn(
                          Color(c.color),
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _target = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('categoryForm.reassignConfirm'),
          onPressed: () => Navigator.pop(context, _target),
          child: const Text('Mover y eliminar'),
        ),
      ],
    );
  }
}
