import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../data/account_repository.dart';
import '../../domain/entities/account_entity.dart';
import '../../domain/entities/pending_capture.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../services/notification_capture_service.dart';
import '../../services/notification_capture_sync_service.dart';
import '../../services/pending_capture_store.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../widgets/account_picker.dart';

class NotificationCapturePage extends StatefulWidget {
  const NotificationCapturePage({super.key});

  @override
  State<NotificationCapturePage> createState() => _NotificationCapturePageState();
}

class _NotificationCapturePageState extends State<NotificationCapturePage> {
  final _captureService = NotificationCaptureService();
  final _store = PendingCaptureStore();

  bool _loading = true;
  bool _accessGranted = false;
  List<PendingCapture> _pending = const [];
  final Set<String> _discarded = {};
  AccountEntity? _account;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final granted = await _captureService.isAccessGranted();
    if (granted) {
      await NotificationCaptureSyncService(
        captureService: _captureService,
        store: _store,
      ).sync();
    }
    final accounts = AccountRepository().getAll();
    if (!mounted) return;
    setState(() {
      _accessGranted = granted;
      _pending = _store.getAll();
      _account = accounts.isNotEmpty ? accounts.first : null;
      _loading = false;
    });
  }

  void _discard(String id) {
    setState(() => _discarded.add(id));
  }

  Future<void> _confirm() async {
    final s = context.strings;
    final toAdd = _pending.where((c) => !_discarded.contains(c.id)).toList();
    if (toAdd.isEmpty) return;

    for (final c in toAdd) {
      context.read<FinanceBloc>().add(AddTransactionRequested(TransactionEntity(
            id: const Uuid().v4(),
            title: c.description,
            amount: c.amount,
            type: c.type,
            category: c.type == TransactionType.income
                ? FinanceCategories.income.last
                : FinanceCategories.expense.last,
            date: DateTime.fromMillisecondsSinceEpoch(c.postTime),
            accountId: _account?.id,
          )));
    }

    await _store.removeMany(_pending.map((c) => c.id));

    if (mounted) AppToast.show(context, s.fin_capture_confirmed(toAdd.length));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final visible = _pending.where((p) => !_discarded.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(title: s.fin_capture_title),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : !_accessGranted
                ? _AccessPrompt(captureService: _captureService, onGranted: _load)
                : ListView(
                    padding: EdgeInsets.fromLTRB(
                      Insets.lg,
                      Insets.md,
                      Insets.lg,
                      MediaQuery.of(context).padding.bottom + Insets.xxl,
                    ),
                    children: [
                      if (visible.isEmpty)
                        Text(
                          s.fin_capture_empty,
                          style: AppType.body.copyWith(color: c.textSecondary),
                        )
                      else ...[
                        for (final capture in visible) ...[
                          _CaptureCard(
                            capture: capture,
                            fmt: fmt,
                            onDiscard: () => _discard(capture.id),
                            discardLabel: s.fin_capture_discard,
                          ),
                          const SizedBox(height: Insets.sm),
                        ],
                        const SizedBox(height: Insets.md),
                        AccountField(
                          label: s.fin_capture_wallet_label,
                          account: _account,
                          onTap: () async {
                            final accounts = AccountRepository().getAll();
                            final picked =
                                await showAccountPicker(context, accounts, _account?.id);
                            if (picked != null) setState(() => _account = picked);
                          },
                        ),
                        const SizedBox(height: Insets.lg),
                        AppButton(
                          label: s.fin_capture_confirm(visible.length),
                          onTap: _confirm,
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _AccessPrompt extends StatelessWidget {
  final NotificationCaptureService captureService;
  final VoidCallback onGranted;

  const _AccessPrompt({required this.captureService, required this.onGranted});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    return Padding(
      padding: const EdgeInsets.all(Insets.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.bell_slash, size: 48, color: c.textSecondary),
          const SizedBox(height: Insets.lg),
          Text(
            s.fin_capture_access_needed,
            style: AppType.title.copyWith(color: c.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Insets.sm),
          Text(
            s.fin_capture_access_explain,
            style: AppType.body.copyWith(color: c.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Insets.xl),
          AppButton(
            label: s.fin_capture_open_settings,
            onTap: () async {
              await captureService.openAccessSettings();
              onGranted();
            },
          ),
        ],
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  final PendingCapture capture;
  final NumberFormat fmt;
  final VoidCallback onDiscard;
  final String discardLabel;

  const _CaptureCard({
    required this.capture,
    required this.fmt,
    required this.onDiscard,
    required this.discardLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isIncome = capture.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(Insets.lg),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(
            isIncome ? CupertinoIcons.arrow_down : CupertinoIcons.arrow_up,
            color: color,
            size: 20,
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capture.description,
                  style: AppType.body.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fmt.format(capture.amount),
                  style: AppType.body.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onDiscard,
            child: Text(discardLabel, style: TextStyle(color: c.textSecondary)),
          ),
        ],
      ),
    );
  }
}
