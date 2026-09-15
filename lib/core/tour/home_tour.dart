import 'package:flutter/widgets.dart';
import '../l10n/app_localizations.dart';
import 'guided_tour.dart';
import 'tour_keys.dart';
import 'tour_step.dart';

Future<void> startHomeTour(
  BuildContext context, {
  required GlobalKey searchKey,
  required GlobalKey balanceKey,
  required List<GlobalKey> groupKeys,
  required Future<void> Function(GlobalKey? key) scrollTo,
}) async {
  final s = context.strings;

  final steps = <TourStep>[
    TourStep(title: s.tour_welcome_title, body: s.tour_welcome_body),
    TourStep(
      targetKey: searchKey,
      title: s.tour_search_title,
      body: s.tour_search_body,
    ),
    TourStep(
      targetKey: balanceKey,
      title: s.tour_balance_title,
      body: s.tour_balance_body,
    ),
    if (groupKeys.isNotEmpty)
      TourStep(
        targetKey: groupKeys[0],
        title: s.tour_money_title,
        body: s.tour_money_body,
      ),
    if (groupKeys.length > 1)
      TourStep(
        targetKey: groupKeys[1],
        title: s.tour_daily_title,
        body: s.tour_daily_body,
      ),
    if (groupKeys.length > 2)
      TourStep(
        targetKey: groupKeys[2],
        title: s.tour_tools_title,
        body: s.tour_tools_body,
      ),
    TourStep(
      targetKey: TourKeys.notifications,
      highlightRadius: 24,
      title: s.tour_notifications_title,
      body: s.tour_notifications_body,
    ),
    TourStep(
      targetKey: TourKeys.profile,
      highlightRadius: 24,
      title: s.tour_profile_title,
      body: s.tour_profile_body,
    ),
  ];

  await showGuidedTour(
    context,
    steps: steps,
    onBeforeStep: (index) => scrollTo(steps[index].targetKey),
  );
}
