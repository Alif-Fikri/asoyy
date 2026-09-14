import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/entities/account_entity.dart';
import 'account_visuals.dart';

Future<AccountEntity?> showAccountPicker(
  BuildContext context,
  List<AccountEntity> accounts,
  String? selectedId,
) =>
    showModalBottomSheet<AccountEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountPickerSheet(
        accounts: accounts,
        selectedId: selectedId,
      ),
    );

class AccountField extends StatelessWidget {
  final String label;
  final AccountEntity? account;
  final VoidCallback onTap;

  const AccountField({
    super.key,
    required this.label,
    required this.account,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final color =
        account == null ? c.textSecondary : accountColor(account!.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: c.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Icon(
                  account == null
                      ? CupertinoIcons.creditcard
                      : accountIcon(account!.type),
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    account?.name ?? s.acc_select,
                    style: TextStyle(
                      color: account == null ? c.textSecondary : c.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(CupertinoIcons.chevron_down,
                    color: c.textSecondary, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountPickerSheet extends StatelessWidget {
  final List<AccountEntity> accounts;
  final String? selectedId;

  const _AccountPickerSheet({required this.accounts, this.selectedId});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.acc_select,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (accounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                s.acc_empty_subtitle,
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: accounts.map((a) {
                  final color = accountColor(a.type);
                  final selected = a.id == selectedId;
                  return InkWell(
                    onTap: () => Navigator.pop(context, a),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Insets.md),
                      child: Row(
                        children: [
                          Container(
                            width: Sizes.iconTile,
                            height: Sizes.iconTile,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(Radii.sm),
                            ),
                            child: Icon(accountIcon(a.type),
                                color: color, size: 18),
                          ),
                          const SizedBox(width: Insets.md),
                          Expanded(
                            child: Text(
                              a.name,
                              style: AppType.body.copyWith(
                                color: c.textPrimary,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(CupertinoIcons.check_mark,
                                color: color, size: 18),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
