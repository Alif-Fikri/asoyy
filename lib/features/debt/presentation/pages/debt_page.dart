import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../bloc/debt_bloc.dart';
import '../bloc/debt_state.dart';
import '../widgets/debt_card.dart';
import 'debt_detail_page.dart';
import 'debt_form_page.dart';

class DebtPage extends StatelessWidget {
  const DebtPage({super.key});

  void _openForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<DebtBloc>(),
          child: const DebtFormPage(),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, String debtId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<DebtBloc>(),
          child: DebtDetailPage(debtId: debtId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(
        title: s.debt_title,
        extraActions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add_circled),
            onPressed: () => _openForm(context),
            tooltip: s.debt_new,
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<DebtBloc, DebtState>(
          listener: (context, state) {
            if (state is DebtError) {
              AppToast.show(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is DebtLoading || state is DebtInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DebtLoaded) {
              if (state.debts.isEmpty) {
                return EmptyStateWidget(
                  icon: CupertinoIcons.person_2,
                  title: s.debt_empty_title,
                  subtitle: s.debt_empty_subtitle,
                );
              }
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.md,
                  Insets.lg,
                  MediaQuery.of(context).padding.bottom + Insets.xxl,
                ),
                itemCount: state.debts.length,
                itemBuilder: (context, i) {
                  final debt = state.debts[i];
                  return DebtCard(
                    debt: debt,
                    onTap: () => _openDetail(context, debt.id),
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
