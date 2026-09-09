import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
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
  final _amountCtrl = TextEditingController(text: '100000');

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
        final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
        final result = amount / fromRate * toRate;
        final fmt = NumberFormat.decimalPattern(
          context.currentLocale.languageCode == 'id' ? 'id_ID' : 'en_US',
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: s.convert_amount,
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: CupertinoIcons.money_dollar,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.converterColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.converterColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.convert_result,
                        style: TextStyle(color: c.textSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      '$_to ${fmt.format(result)}',
                      style: const TextStyle(
                        color: AppColors.converterColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                      style: TextStyle(color: c.textSecondary, fontSize: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.cardLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: c.card,
          style: TextStyle(color: c.textPrimary, fontSize: 14),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.wifi_slash, size: 40, color: c.textHint),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
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
