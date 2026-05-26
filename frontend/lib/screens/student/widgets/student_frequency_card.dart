import 'package:flutter/material.dart';

import '../student_models.dart';
import '../student_theme.dart';
import 'student_section_title.dart';

class StudentFrequencyCard extends StatelessWidget {
  final List<StudentWorkoutPlan> workouts;
  final List<StudentTrainingSession> trainingSessions;
  final DateTime selectedDate;
  final ValueChanged<int> onWeekdaySelected;

  const StudentFrequencyCard({
    super.key,
    required this.workouts,
    this.trainingSessions = const [],
    required this.selectedDate,
    required this.onWeekdaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: StudentTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudentSectionTitle(
            title: 'Frequencia de Treinos',
            subtitle: '',
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(7, (index) {
              final weekday = index + 1;
              final hasWorkout =
                  workouts.any(
                    (workout) =>
                        workout.scheduledDate != null &&
                        workout.weekday == weekday,
                  ) ||
                  trainingSessions.any(
                    (session) => session.date.weekday == weekday,
                  );
              final isSelected = weekday == selectedDate.weekday;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => onWeekdaySelected(weekday),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? StudentTheme.blue
                                  : const Color(0xFF2C2C2E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected || hasWorkout
                                    ? StudentTheme.blue
                                    : const Color(0xFFD7DEE9),
                            width: 2.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            hasWorkout
                                ? Icons.priority_high
                                : Icons.circle,
                            size: hasWorkout ? 22 : 8,
                            color:
                                isSelected
                                    ? Colors.black
                                    : hasWorkout
                                    ? StudentTheme.blue
                                    : Colors.transparent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        StudentDateLabels.weekdayShort(weekday)[0],
                        style: const TextStyle(
                          color: StudentTheme.darkText,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
