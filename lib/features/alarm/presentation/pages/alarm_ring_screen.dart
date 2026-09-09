import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/design_tokens.dart';

class AlarmRingScreen extends StatefulWidget {
  final String label;
  final String time;
  final VoidCallback onStop;
  final VoidCallback onSnooze;

  const AlarmRingScreen({
    super.key,
    required this.label,
    required this.time,
    required this.onStop,
    required this.onSnooze,
  });

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF241233), AppColors.background],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
              child: Column(
                children: [
                  const SizedBox(height: Insets.xxl),
                  Text(
                    s.alarm_ringing_now.toUpperCase(),
                    style: AppType.label.copyWith(
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const Spacer(),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final t = _pulse.value;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 150 + t * 40,
                            height: 150 + t * 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(
                                alpha: 0.12 * (1 - t),
                              ),
                            ),
                          ),
                          child!,
                        ],
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryLight,
                            AppColors.primaryDark,
                          ],
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.alarm_fill,
                        size: 52,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: Insets.xxl),
                  Text(
                    widget.time,
                    style: AppType.display.copyWith(
                      fontSize: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: Insets.sm),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: AppType.title.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const Spacer(flex: 2),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                      ),
                      onPressed: widget.onStop,
                      child: Text(s.alarm_stop, style: AppType.bodyStrong),
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.pill),
                        ),
                      ),
                      onPressed: widget.onSnooze,
                      child: Text(s.alarm_snooze, style: AppType.bodyStrong),
                    ),
                  ),
                  const SizedBox(height: Insets.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
