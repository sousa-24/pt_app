import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../student_models.dart';
import '../student_theme.dart';

class StudentWorkoutCard extends StatelessWidget {
  final StudentWorkoutPlan workout;
  final bool isCompleted;
  final VoidCallback onOpen;

  const StudentWorkoutCard({
    super.key,
    required this.workout,
    required this.isCompleted,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: StudentTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: workout.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(workout.icon, color: workout.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.title,
                      style: const TextStyle(
                        color: StudentTheme.darkText,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${workout.focus} | ${workout.durationMinutes} min',
                      style: const TextStyle(
                        color: StudentTheme.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(isCompleted: isCompleted),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                workout.exercises
                    .map(
                      (exercise) => Chip(
                        label: Text(exercise),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                        backgroundColor: const Color(0xFF3A3A3D),
                        labelStyle: const TextStyle(
                          color: StudentTheme.darkText,
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.visibility_outlined),
              label: Text(
                isCompleted ? l10n.viewCompletedWorkoutAction : l10n.viewWorkoutAction,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCompleted ? const Color(0xFF3A3A3D) : workout.color,
                foregroundColor:
                    isCompleted ? StudentTheme.darkText : Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isCompleted;

  const _StatusPill({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:
            isCompleted
                ? const Color(0xFF24351F)
                : const Color(0xFF3A3321),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isCompleted ? l10n.completedStatusLabel : l10n.pendingStatusLabel,
        style: TextStyle(
          color:
              isCompleted ? StudentTheme.blue : const Color(0xFFFFD36A),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
