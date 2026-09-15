import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/ios_section.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../../alarm/domain/entities/alarm_entity.dart';
import '../../../alarm/presentation/bloc/alarm_bloc.dart';
import '../../../alarm/presentation/bloc/alarm_state.dart';
import '../../../alarm/presentation/pages/alarm_page.dart';
import '../../../calendar/domain/entities/event_entity.dart';
import '../../../calendar/presentation/bloc/calendar_bloc.dart';
import '../../../calendar/presentation/bloc/calendar_state.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../../finance/domain/entities/transaction_entity.dart';
import '../../../finance/presentation/bloc/finance_bloc.dart';
import '../../../finance/presentation/bloc/finance_state.dart';
import '../../../finance/presentation/pages/finance_page.dart';
import '../../../password/domain/entities/password_entity.dart';
import '../../../password/presentation/bloc/password_bloc.dart';
import '../../../password/presentation/bloc/password_state.dart';
import '../../../password/presentation/pages/password_flow_page.dart';
import '../../../debt/domain/entities/debt_entity.dart';
import '../../../debt/presentation/bloc/debt_bloc.dart';
import '../../../debt/presentation/bloc/debt_state.dart';
import '../../../debt/presentation/pages/debt_page.dart';
import '../../../finance/data/account_repository.dart';
import '../../../finance/domain/entities/account_entity.dart';
import '../../../notes/domain/entities/note_entity.dart';
import '../../../notes/presentation/bloc/note_bloc.dart';
import '../../../notes/presentation/bloc/note_state.dart';
import '../../../notes/presentation/pages/notes_page.dart';
import '../../../split_bill/domain/entities/bill_entity.dart';
import '../../../split_bill/presentation/bloc/split_bill_bloc.dart';
import '../../../split_bill/presentation/bloc/split_bill_state.dart';
import '../../../split_bill/presentation/pages/split_bill_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(List<String?> fields) {
    final q = _query.trim().toLowerCase();
    return fields.any((f) => f != null && f.toLowerCase().contains(q));
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final isId = context.currentLocale.languageCode == 'id';

    final financeState = context.watch<FinanceBloc>().state;
    final calendarState = context.watch<CalendarBloc>().state;
    final passwordState = context.watch<PasswordBloc>().state;
    final alarmState = context.watch<AlarmBloc>().state;
    final noteState = context.watch<NoteBloc>().state;
    final debtState = context.watch<DebtBloc>().state;
    final billState = context.watch<SplitBillBloc>().state;

    final transactions =
        financeState is FinanceLoaded ? financeState.all : <TransactionEntity>[];
    final events =
        calendarState is CalendarLoaded ? calendarState.events : <EventEntity>[];
    final passwords =
        passwordState is PasswordLoaded ? passwordState.all : <PasswordEntity>[];
    final alarms = alarmState is AlarmLoaded ? alarmState.alarms : <AlarmEntity>[];
    final notes = noteState is NoteLoaded ? noteState.notes : <NoteEntity>[];
    final debts = debtState is DebtLoaded ? debtState.debts : <DebtEntity>[];
    final bills =
        billState is SplitBillLoaded ? billState.bills : <BillEntity>[];
    final wallets = AccountRepository().getAll();

    final showResults = _query.trim().isNotEmpty;

    final matchedTransactions = showResults
        ? transactions.where((t) => _matches([t.title, t.category, t.notes])).toList()
        : <TransactionEntity>[];
    final matchedEvents = showResults
        ? events.where((e) => _matches([e.title, e.description])).toList()
        : <EventEntity>[];
    final matchedPasswords = showResults
        ? passwords
            .where((p) => _matches([p.title, p.username, p.website, p.notes]))
            .toList()
        : <PasswordEntity>[];
    final matchedAlarms = showResults
        ? alarms.where((a) => _matches([a.label])).toList()
        : <AlarmEntity>[];

    final matchedNotes = showResults
        ? notes
            .where((n) => _matches([
                  n.title,
                  n.body,
                  ...n.items.map((i) => i.text),
                ]))
            .toList()
        : <NoteEntity>[];
    final matchedDebts = showResults
        ? debts.where((d) => _matches([d.personName, d.note])).toList()
        : <DebtEntity>[];
    final matchedBills = showResults
        ? bills
            .where((b) => _matches([
                  b.title,
                  ...b.participants.map((p) => p.name),
                ]))
            .toList()
        : <BillEntity>[];
    final matchedWallets = showResults
        ? wallets.where((a) => _matches([a.name])).toList()
        : <AccountEntity>[];

    final totalResults = matchedTransactions.length +
        matchedEvents.length +
        matchedPasswords.length +
        matchedAlarms.length +
        matchedNotes.length +
        matchedDebts.length +
        matchedBills.length +
        matchedWallets.length;

    final dateFmt = DateFormat('d MMM yyyy', isId ? 'id_ID' : 'en_US');
    final currencyFmt = NumberFormat.compact(locale: 'id_ID');

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(title: s.search_title),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(color: c.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: s.search_hint,
                    hintStyle: TextStyle(color: c.textHint, fontSize: 14),
                    prefixIcon: Icon(CupertinoIcons.search, color: c.textSecondary),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(CupertinoIcons.clear_circled_solid,
                                color: c.textSecondary),
                            onPressed: () => setState(() {
                              _controller.clear();
                              _query = '';
                            }),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: !showResults
                  ? EmptyStateWidget(
                      icon: CupertinoIcons.search,
                      title: s.search_prompt_title,
                      subtitle: s.search_prompt_subtitle,
                    )
                  : totalResults == 0
                      ? EmptyStateWidget(
                          icon: CupertinoIcons.search,
                          title: s.search_empty_title,
                          subtitle: s.search_empty_subtitle,
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            if (matchedTransactions.isNotEmpty)
                              IosSection(
                                header: s.search_section_finance,
                                children: matchedTransactions
                                    .map((t) => IosRow(
                                          leading: IosIcon(
                                            icon: t.isIncome
                                                ? CupertinoIcons.arrow_down_circle_fill
                                                : CupertinoIcons.arrow_up_circle_fill,
                                            color: t.isIncome
                                                ? AppColors.income
                                                : AppColors.expense,
                                          ),
                                          title: t.title,
                                          subtitle:
                                              '${t.category} · ${dateFmt.format(t.date)}',
                                          trailing: Text(
                                            'Rp ${currencyFmt.format(t.amount)}',
                                            style: TextStyle(
                                              color: c.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          showChevron: true,
                                          onTap: () => _open(const FinancePage()),
                                        ))
                                    .toList(),
                              ),
                            if (matchedEvents.isNotEmpty)
                              IosSection(
                                header: s.search_section_calendar,
                                children: matchedEvents
                                    .map((e) => IosRow(
                                          leading: IosIcon(
                                            icon: CupertinoIcons.calendar,
                                            color: AppColors.calendarColor,
                                          ),
                                          title: e.title,
                                          subtitle: dateFmt.format(e.date),
                                          showChevron: true,
                                          onTap: () => _open(const CalendarPage()),
                                        ))
                                    .toList(),
                              ),
                            if (matchedPasswords.isNotEmpty)
                              IosSection(
                                header: s.search_section_password,
                                children: matchedPasswords
                                    .map((p) => IosRow(
                                          leading: IosIcon(
                                            icon: CupertinoIcons.lock_fill,
                                            color: AppColors.passwordColor,
                                          ),
                                          title: p.title,
                                          subtitle: p.username,
                                          showChevron: true,
                                          onTap: () =>
                                              _open(const PasswordFlowPage()),
                                        ))
                                    .toList(),
                              ),
                            if (matchedAlarms.isNotEmpty)
                              IosSection(
                                header: s.search_section_alarm,
                                children: matchedAlarms
                                    .map((a) => IosRow(
                                          leading: IosIcon(
                                            icon: CupertinoIcons.alarm_fill,
                                            color: AppColors.alarmColor,
                                          ),
                                          title: a.label,
                                          subtitle: a.timeString,
                                          showChevron: true,
                                          onTap: () => _open(const AlarmPage()),
                                        ))
                                    .toList(),
                              ),
                            if (matchedNotes.isNotEmpty)
                              IosSection(
                                header: s.search_section_notes,
                                children: matchedNotes
                                    .map((n) => IosRow(
                                          leading: const IosIcon(
                                            icon:
                                                CupertinoIcons.checkmark_square,
                                            color: AppColors.income,
                                          ),
                                          title: n.title,
                                          subtitle: n.isChecklist
                                              ? s.notes_progress(
                                                  n.doneCount, n.items.length)
                                              : (n.body ?? ''),
                                          showChevron: true,
                                          onTap: () => _open(
                                            BlocProvider.value(
                                              value: context.read<NoteBloc>(),
                                              child: const NotesPage(),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            if (matchedDebts.isNotEmpty)
                              IosSection(
                                header: s.search_section_debt,
                                children: matchedDebts
                                    .map((d) => IosRow(
                                          leading: const IosIcon(
                                            icon: CupertinoIcons.person_2_fill,
                                            color: AppColors.debtColor,
                                          ),
                                          title: d.personName,
                                          subtitle: d.note ?? '',
                                          trailing: Text(
                                            'Rp ${currencyFmt.format(d.amount)}',
                                            style: TextStyle(
                                              color: c.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          showChevron: true,
                                          onTap: () => _open(
                                            BlocProvider.value(
                                              value: context.read<DebtBloc>(),
                                              child: const DebtPage(),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            if (matchedBills.isNotEmpty)
                              IosSection(
                                header: s.search_section_splitbill,
                                children: matchedBills
                                    .map((b) => IosRow(
                                          leading: const IosIcon(
                                            icon: CupertinoIcons.person_3_fill,
                                            color: AppColors.splitBillColor,
                                          ),
                                          title: b.title,
                                          subtitle: dateFmt.format(b.date),
                                          trailing: Text(
                                            'Rp ${currencyFmt.format(b.totalAmount)}',
                                            style: TextStyle(
                                              color: c.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                          showChevron: true,
                                          onTap: () => _open(
                                            BlocProvider.value(
                                              value:
                                                  context.read<SplitBillBloc>(),
                                              child: const SplitBillPage(),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            if (matchedWallets.isNotEmpty)
                              IosSection(
                                header: s.search_section_wallet,
                                children: matchedWallets
                                    .map((a) => IosRow(
                                          leading: const IosIcon(
                                            icon: CupertinoIcons.creditcard_fill,
                                            color: AppColors.financeColor,
                                          ),
                                          title: a.name,
                                          showChevron: true,
                                          onTap: () => _open(const FinancePage()),
                                        ))
                                    .toList(),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
