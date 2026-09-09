import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/utils/unit_conversion.dart';
import '../../../../core/widgets/app_text_field.dart';

class UnitConverterTab extends StatefulWidget {
  const UnitConverterTab({super.key});

  @override
  State<UnitConverterTab> createState() => _UnitConverterTabState();
}

class _UnitConverterTabState extends State<UnitConverterTab> {
  UnitCategory _category = UnitCategory.length;
  String _from = 'm';
  String _to = 'km';
  final _amountCtrl = TextEditingController(text: '1');

  static const _defaults = {
    UnitCategory.length: ['m', 'km'],
    UnitCategory.weight: ['kg', 'g'],
    UnitCategory.temperature: ['c', 'f'],
    UnitCategory.volume: ['l', 'ml'],
  };

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String _categoryLabel(UnitCategory c, AppStrings s) => switch (c) {
        UnitCategory.length => s.convert_cat_length,
        UnitCategory.weight => s.convert_cat_weight,
        UnitCategory.temperature => s.convert_cat_temperature,
        UnitCategory.volume => s.convert_cat_volume,
      };

  String _unitLabel(String code, AppStrings s) => switch (code) {
        'mm' => s.convert_unit_mm,
        'cm' => s.convert_unit_cm,
        'm' => s.convert_unit_m,
        'km' => s.convert_unit_km,
        'in' => s.convert_unit_in,
        'ft' => s.convert_unit_ft,
        'yd' => s.convert_unit_yd,
        'mi' => s.convert_unit_mi,
        'mg' => s.convert_unit_mg,
        'g' => s.convert_unit_g,
        'kg' => s.convert_unit_kg,
        'ton' => s.convert_unit_ton,
        'oz' => s.convert_unit_oz,
        'lb' => s.convert_unit_lb,
        'ml' => s.convert_unit_ml,
        'l' => s.convert_unit_l,
        'm3' => s.convert_unit_m3,
        'gal' => s.convert_unit_gal,
        'cup' => s.convert_unit_cup,
        'c' => s.convert_unit_c,
        'f' => s.convert_unit_f,
        'k' => s.convert_unit_k,
        _ => code,
      };

  void _onCategoryChanged(UnitCategory category) {
    final defaults = _defaults[category]!;
    setState(() {
      _category = category;
      _from = defaults[0];
      _to = defaults[1];
    });
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final units = unitsFor(_category, labelOf: (code) => _unitLabel(code, s));
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final result = convertUnit(_category, _from, _to, amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.convert_category.toUpperCase(),
            style: AppType.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            children: UnitCategory.values.map((cat) {
              return AppChip(
                label: _categoryLabel(cat, s),
                isSelected: cat == _category,
                color: AppColors.converterColor,
                onTap: () => _onCategoryChanged(cat),
              );
            }).toList(),
          ),
          const SizedBox(height: Insets.xl),
          AppTextField(
            label: s.convert_amount,
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: CupertinoIcons.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Insets.lg),
          Row(
            children: [
              Expanded(child: _UnitDropdown(
                value: _from,
                units: units,
                onChanged: (v) => setState(() => _from = v),
              )),
              IconButton(
                onPressed: _swap,
                icon: Icon(CupertinoIcons.arrow_right_arrow_left,
                    color: AppColors.converterColor),
              ),
              Expanded(child: _UnitDropdown(
                value: _to,
                units: units,
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
                  _formatNumber(result),
                  style: AppType.display.copyWith(
                    color: AppColors.converterColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e12) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
}

class _UnitDropdown extends StatelessWidget {
  final String value;
  final List<UnitDef> units;
  final void Function(String) onChanged;

  const _UnitDropdown({
    required this.value,
    required this.units,
    required this.onChanged,
  });

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
          items: units
              .map((u) => DropdownMenuItem(value: u.code, child: Text(u.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
