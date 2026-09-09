import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/converter_cubit.dart';
import '../bloc/converter_state.dart';

const _currencies = [
  'IDR', 'USD', 'EUR', 'JPY', 'GBP', 'AUD', 'SGD',
  'MYR', 'CNY', 'KRW', 'SAR', 'THB', 'HKD', 'INR', 'CHF',
];

class CurrencyConverterTab extends StatefulWidget {
  const CurrencyConverterTab({super.key});

  @override
  State<CurrencyConverterTab> createState() => _CurrencyConverterTabState();
}

class _CurrencyConverterTabState extends State<CurrencyConverterTab> {
  String _from = 'IDR';
  String _to = 'USD';
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  String _lastUpdatedLabel(DateTime fetchedAt, AppStrings s) {
    final diff = DateTime.now().difference(fetchedAt);
    if (diff.inMinutes < 1) return s.convert_last_updated_now;
    if (diff.inHours < 1) return s.convert_last_updated_minutes(diff.inMinutes);
    return s.convert_last_updated_hours(diff.inHours);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return BlocBuilder<ConverterCubit, ConverterRatesState>(
      builder: (context, state) {
        if (state is ConverterRatesError) {
          return _ErrorView(
            message: s.convert_offline_error,
            onRetry: () => context.read<ConverterCubit>().retry(),
          );
        }
        if (state is! ConverterRatesLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final rates = state.rates.rates;
        final fromRate = rates[_from] ?? 1;
        final toRate = rates[_to] ?? 1;
        final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;
        final result = amount / fromRate * toRate;
        final fmt = NumberFormat.decimalPattern(
          context.currentLocale.languageCode == 'id' ? 'id_ID' : 'en_US',
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: s.convert_amount,
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [_ThousandsInputFormatter()],
                prefixIcon: CupertinoIcons.money_dollar,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: Insets.lg),
              Row(
                children: [
                  Expanded(child: _CurrencyDropdown(
                    value: _from,
                    onChanged: (v) => setState(() => _from = v),
                  )),
                  IconButton(
                    onPressed: _swap,
                    icon: Icon(CupertinoIcons.arrow_right_arrow_left,
                        color: AppColors.converterColor),
                  ),
                  Expanded(child: _CurrencyDropdown(
                    value: _to,
                    onChanged: (v) => setState(() => _to = v),
                  )),
                ],
              ),
              const SizedBox(height: Insets.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Insets.lg),
                decoration: BoxDecoration(
                  color: AppColors.converterColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: Border.all(
                    color: AppColors.converterColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.convert_result.toUpperCase(),
                      style: AppType.label.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: Insets.sm),
                    Text(
                      '$_to ${fmt.format(result)}',
                      style: AppType.display.copyWith(
                        color: AppColors.converterColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Insets.lg),
              Row(
                children: [
                  Icon(
                    state.refreshFailed
                        ? CupertinoIcons.wifi_slash
                        : CupertinoIcons.checkmark_circle,
                    size: 14,
                    color: state.refreshFailed
                        ? AppColors.alarmColor
                        : c.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      state.refreshing
                          ? s.convert_refreshing
                          : state.refreshFailed
                              ? s.convert_offline_stale
                              : _lastUpdatedLabel(state.rates.fetchedAt, s),
                      style: AppType.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  const _CurrencyDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.md),
      decoration: BoxDecoration(
        color: c.cardLight,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: c.card,
          style: AppType.body.copyWith(color: c.textPrimary),
          items: _currencies
              .map((code) => DropdownMenuItem(value: code, child: Text(code)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write('.');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.wifi_slash, size: 40, color: c.textHint),
            const SizedBox(height: Insets.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppType.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: Insets.lg),
            TextButton(
              onPressed: onRetry,
              child: Text(s.convert_retry),
            ),
          ],
        ),
      ),
    );
  }
}
