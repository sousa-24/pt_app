import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../student_theme.dart';

class StudentHydrationCard extends StatelessWidget {
  final int currentMl;
  final int goalMl;
  final VoidCallback onAddSmall;
  final VoidCallback onAddMedium;
  final VoidCallback onRemoveSmall;
  final VoidCallback onReset;

  const StudentHydrationCard({
    super.key,
    required this.currentMl,
    required this.goalMl,
    required this.onAddSmall,
    required this.onAddMedium,
    required this.onRemoveSmall,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final safeGoal = goalMl <= 0 ? 1 : goalMl;
    final progress = math.min(currentMl / safeGoal, 1.0);
    final percentage = (progress * 100).round();
    final consumedLiters = currentMl / 1000;
    final goalLiters = safeGoal / 1000;
    final remainingMl = math.max(safeGoal - currentMl, 0);
    final targetNowMl = _targetMlForCurrentTime(safeGoal);
    final behindMl = math.max(targetNowMl - currentMl, 0);
    final nextReminder = _nextReminderLabel(l10n);
    final statusText = remainingMl == 0
        ? l10n.goalCompletedTodayLabel
        : behindMl > 0
            ? l10n.drinkNowLabel(_formatCups(behindMl, l10n))
            : l10n.onTrackLabel;
    final statusColor =
        remainingMl == 0 || behindMl == 0 ? StudentTheme.blue : Colors.amber;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: StudentTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.hydrationTitle,
                  style: const TextStyle(
                    color: StudentTheme.darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: StudentTheme.blue,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final progressRing = SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFF3A3A3D),
                        color: StudentTheme.blue,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.water_drop,
                          color: StudentTheme.blue,
                          size: 22,
                        ),
                        Text(
                          '${consumedLiters.toStringAsFixed(1)} L',
                          style: const TextStyle(
                            color: StudentTheme.darkText,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          l10n.ofGoalLitersLabel(goalLiters.toStringAsFixed(1)),
                          style: const TextStyle(
                            color: StudentTheme.mutedText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    remainingMl == 0
                        ? l10n.dailyGoalCompletedLabel
                        : l10n.remainingTodayLabel(_formatMl(remainingMl)),
                    style: const TextStyle(
                      color: StudentTheme.darkText,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.loggedOfGoalLabel(_formatMl(currentMl), _formatMl(safeGoal)),
                    style: const TextStyle(
                      color: StudentTheme.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          behindMl > 0
                              ? Icons.notifications_active_outlined
                              : Icons.check_circle_outline,
                          color: statusColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.nextReminderLabel(nextReminder),
                    style: const TextStyle(
                      color: StudentTheme.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HydrationButton(
                        label: '-250 ml',
                        onPressed: currentMl > 0 ? onRemoveSmall : null,
                      ),
                      _HydrationButton(
                        label: '+250 ml',
                        onPressed: currentMl < safeGoal ? onAddSmall : null,
                        isPrimary: true,
                      ),
                      _HydrationButton(
                        label: '+500 ml',
                        onPressed: currentMl < safeGoal ? onAddMedium : null,
                        isPrimary: true,
                      ),
                    ],
                  ),
                ],
              );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  progressRing,
                  const SizedBox(width: 16),
                  Expanded(child: details),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(99),
                    backgroundColor: const Color(0xFF3A3A3D),
                    color: StudentTheme.blue,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: currentMl > 0 ? onReset : null,
                  style: TextButton.styleFrom(
                    foregroundColor: StudentTheme.mutedText,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(l10n.resetAction),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMl(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} L';
    }

    return '$value ml';
  }

  static String _formatCups(int value, AppLocalizations l10n) {
    final cups = math.max((value / 250).round(), 1);
    return cups == 1 ? l10n.cupSingularLabel : l10n.cupsPluralLabel(cups.toString());
  }

  static int _targetMlForCurrentTime(int goalMl) {
    final now = DateTime.now();
    const startHour = 8;
    const endHour = 22;
    const activeMinutes = (endHour - startHour) * 60;
    final minutesNow = (now.hour - startHour) * 60 + now.minute;
    final elapsed = minutesNow.clamp(0, activeMinutes);
    return ((goalMl * elapsed) / activeMinutes).round();
  }

  static String _nextReminderLabel(AppLocalizations l10n) {
    final now = DateTime.now();
    const reminderHours = [8, 10, 12, 14, 16, 18, 20, 22];
    final nextHour = reminderHours.firstWhere(
      (hour) => hour > now.hour || (hour == now.hour && now.minute == 0),
      orElse: () => reminderHours.first,
    );

    if (nextHour == reminderHours.first && now.hour >= reminderHours.last) {
      return l10n.tomorrowAtLabel('08:00');
    }

    return '${nextHour.toString().padLeft(2, '0')}:00';
  }
}

class _HydrationButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _HydrationButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 72),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor:
                isPrimary ? StudentTheme.blue : const Color(0xFF3A3A3D),
            foregroundColor: isPrimary ? Colors.black : StudentTheme.darkText,
            disabledBackgroundColor: const Color(0xFF2C2C2E),
            disabledForegroundColor: StudentTheme.mutedText,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
