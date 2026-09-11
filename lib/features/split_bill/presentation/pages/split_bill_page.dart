import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../bloc/split_bill_bloc.dart';
import '../bloc/split_bill_state.dart';
import '../widgets/bill_card.dart';
import 'split_bill_detail_page.dart';
import 'split_bill_form_page.dart';

class SplitBillPage extends StatelessWidget {
  const SplitBillPage({super.key});

  void _openForm(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<SplitBillBloc>(),
          child: const SplitBillFormPage(),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, String billId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<SplitBillBloc>(),
          child: SplitBillDetailPage(billId: billId),
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
      appBar: NexusAppBar(title: s.splitbill_title),
      body: SafeArea(
        child: BlocConsumer<SplitBillBloc, SplitBillState>(
          listener: (context, state) {
            if (state is SplitBillError) {
              AppToast.show(context, state.message);
            }
          },
          builder: (context, state) {
            if (state is SplitBillLoading || state is SplitBillInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is SplitBillLoaded) {
              if (state.bills.isEmpty) {
                return EmptyStateWidget(
                  icon: CupertinoIcons.money_dollar_circle,
                  title: s.splitbill_empty_title,
                  subtitle: s.splitbill_empty_subtitle,
                );
              }
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.md,
                  Insets.lg,
                  MediaQuery.of(context).padding.bottom + Insets.xxl,
                ),
                itemCount: state.bills.length,
                itemBuilder: (context, i) {
                  final bill = state.bills[i];
                  return BillCard(
                    bill: bill,
                    onTap: () => _openDetail(context, bill.id),
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.splitBillColor,
        onPressed: () => _openForm(context),
        child: const Icon(CupertinoIcons.add, color: Colors.white),
      ),
    );
  }
}
