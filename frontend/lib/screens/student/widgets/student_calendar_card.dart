import 'package:flutter/material.dart';

import '../student_models.dart';
import '../student_theme.dart';
import 'student_section_title.dart';

class StudentCalendarCard extends StatelessWidget {
  final DateTime selectedDate;
  final Set<String> completedWorkoutIds;
  final List<StudentWorkoutPlan> Function(DateTime date) plansForDate;
  final ValueChanged<DateTime> onDateSelected;

  const StudentCalendarCard({
    super.key,
    required this.selectedDate,
    required this.completedWorkoutIds,
    required this.plansForDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month);
    final monthDays = DateUtils.getDaysInMonth(now.year, now.month);
    final leadingEmptyDays = firstDay.weekday - 1;
    final totalCells = leadingEmptyDays + monthDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudentTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentSectionTitle(
            title: StudentDateLabels.monthTitle(now),
            subtitle: 'Calendario',
          ),
          const SizedBox(height: 16),
          Row(
            children:
                List.generate(7, (index) => index + 1)
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            StudentDateLabels.weekdayShort(day),
                            style: const TextStyle(
                              color: StudentTheme.mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: totalCells,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyDays) {
                return const SizedBox.shrink();
              }

              final dayNumber = index - leadingEmptyDays + 1;
              final date = DateTime(now.year, now.month, dayNumber);
              final normalizedDate = DateTime(date.year, date.month, date.day);
              final isSelected = normalizedDate == selectedDate;
              final plans = plansForDate(date);
              final hasWorkout = plans.isNotEmpty;
              final isCompleted =
                  plans.isNotEmpty &&
                  plans.every((plan) => completedWorkoutIds.contains(plan.id));

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onDateSelected(normalizedDate),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? StudentTheme.blue
                            : isCompleted
                            ? const Color(0xFF24351F)
                            : hasWorkout
                            ? const Color(0xFF343A2B)
                            : const Color(0xFF242426),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected
                              ? StudentTheme.blue
                              : hasWorkout
                              ? StudentTheme.blue.withOpacity(0.35)
                              : const Color(0xFF3A3A3D),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors.black
                                  : StudentTheme.darkText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (hasWorkout)
                        Icon(
                          isCompleted
                              ? Icons.check_circle
                              : Icons.fitness_center,
                          size: 13,
                          color:
                              isSelected
                                  ? Colors.black
                                  : isCompleted
                                  ? StudentTheme.blue
                                  : StudentTheme.blue,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
