import 'package:flutter/material.dart';

import '../../core/security_question.dart';
import '../../core/validators.dart';
import '../../l10n/l10n.dart';

/// What the user picked in [SecurityQuestionFields]: a list question or
/// their own, plus the answer.
class SecurityQuestionInput {
  SecurityQuestionInput({SecurityQuestion? initial})
    : choice = switch (initial) {
        PresetQuestion(:final preset) => preset,
        CustomQuestion() => _custom,
        null => null,
      },
      custom = TextEditingController(
        text: initial is CustomQuestion ? initial.text : null,
      );

  /// A [SecurityQuestionPreset], [_custom] or null (nothing chosen yet).
  Object? choice;
  final TextEditingController custom;
  final answer = TextEditingController();

  bool get isCustom => identical(choice, _custom);

  /// Only valid after the form validated.
  SecurityQuestion get question => isCustom
      ? CustomQuestion(custom.text.trim())
      : PresetQuestion(choice! as SecurityQuestionPreset);

  void dispose() {
    custom.dispose();
    answer.dispose();
  }
}

/// Marker for "Escribir mi propia pregunta" in the dropdown.
const Object _custom = 'custom';

/// Question (list or own) and answer. Keys: `<keyPrefix>.securityQuestion`
/// (its options `<keyPrefix>.securityQuestion.<preset|custom>`),
/// `<keyPrefix>.customQuestion`, `<keyPrefix>.securityAnswer`.
class SecurityQuestionFields extends StatefulWidget {
  const SecurityQuestionFields({
    super.key,
    required this.input,
    required this.keyPrefix,
    this.textInputAction = TextInputAction.next,
  });

  final SecurityQuestionInput input;
  final String keyPrefix;
  final TextInputAction textInputAction;

  @override
  State<SecurityQuestionFields> createState() => _SecurityQuestionFieldsState();
}

class _SecurityQuestionFieldsState extends State<SecurityQuestionFields> {
  SecurityQuestionInput get _in => widget.input;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<Object>(
          key: ValueKey('${widget.keyPrefix}.securityQuestion'),
          initialValue: _in.choice,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l.securityQuestionLabel,
            prefixIcon: const Icon(Icons.help_outline),
          ),
          validator: (v) => v == null ? l.fieldQuestionChoose : null,
          items: [
            for (final p in SecurityQuestionPreset.values)
              DropdownMenuItem(
                key: ValueKey('${widget.keyPrefix}.securityQuestion.${p.name}'),
                value: p,
                child: Text(
                  l.securityQuestionText(PresetQuestion(p)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            DropdownMenuItem(
              key: ValueKey('${widget.keyPrefix}.securityQuestion.custom'),
              value: _custom,
              child: Text(l.secQCustom),
            ),
          ],
          // Long questions wrap in the menu but stay on one line once picked.
          selectedItemBuilder: (context) => [
            for (final p in SecurityQuestionPreset.values)
              Text(
                l.securityQuestionText(PresetQuestion(p)),
                overflow: TextOverflow.ellipsis,
              ),
            Text(l.secQCustom, overflow: TextOverflow.ellipsis),
          ],
          onChanged: (v) => setState(() => _in.choice = v),
        ),
        if (_in.isCustom) ...[
          const SizedBox(height: 14),
          TextFormField(
            key: ValueKey('${widget.keyPrefix}.customQuestion'),
            controller: _in.custom,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            maxLength: SecurityQuestion.customMaxLength,
            validator: (v) => l.fieldError(validateCustomQuestion(v)),
            decoration: InputDecoration(
              labelText: l.customQuestionLabel,
              prefixIcon: const Icon(Icons.edit_outlined),
              counterText: '',
            ),
          ),
        ],
        const SizedBox(height: 14),
        TextFormField(
          key: ValueKey('${widget.keyPrefix}.securityAnswer'),
          controller: _in.answer,
          textInputAction: widget.textInputAction,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: securityAnswerMaxLength,
          validator: (v) => l.fieldError(validateSecurityAnswer(v)),
          decoration: InputDecoration(
            labelText: l.securityAnswerLabel,
            prefixIcon: const Icon(Icons.key_outlined),
            counterText: '',
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 6),
          child: Text(l.securityAnswerHint, style: muted),
        ),
      ],
    );
  }
}
