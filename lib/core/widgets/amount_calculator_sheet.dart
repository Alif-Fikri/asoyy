import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_color_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/simple_calculator.dart';
import 'app_button.dart';

Future<double?> showAmountCalculatorSheet(BuildContext context) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AmountCalculatorSheet(),
  );
}

class _AmountCalculatorSheet extends StatefulWidget {
  const _AmountCalculatorSheet();

  @override
  State<_AmountCalculatorSheet> createState() => _AmountCalculatorSheetState();
}

class _AmountCalculatorSheetState extends State<_AmountCalculatorSheet> {
  final _ctrl = TextEditingController();
  double? _result;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      setState(() => _result = evaluateExpression(_ctrl.text));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Insets.lg,
        Insets.lg,
        Insets.lg,
        MediaQuery.of(context).viewInsets.bottom + Insets.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(Insets.lg),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.calc_title, style: AppType.title.copyWith(color: c.textPrimary)),
            const SizedBox(height: Insets.sm),
            Text(s.amount_calc_hint, style: AppType.body.copyWith(color: c.textSecondary)),
            const SizedBox(height: Insets.md),
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              style: TextStyle(color: c.textPrimary, fontSize: 20),
              decoration: InputDecoration(
                hintText: '1000 + 2500 * 3',
                prefixIcon: const Icon(CupertinoIcons.function),
              ),
              onSubmitted: (_) {
                if (_result != null) Navigator.pop(context, _result);
              },
            ),
            const SizedBox(height: Insets.sm),
            Text(
              _result != null ? '= ${_result!.toStringAsFixed(0)}' : '',
              style: AppType.title.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: Insets.lg),
            AppButton(
              label: s.amount_calc_use_result,
              onTap: _result != null ? () => Navigator.pop(context, _result) : null,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
