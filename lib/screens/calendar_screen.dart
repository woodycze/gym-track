import 'package:flutter/material.dart';
import '../models.dart';

class CalendarScreen extends StatefulWidget {
  final String title = 'Kalendář';
  final List<Workout> pastWorkouts;
  final Map<int, String> schedule;
  final List<WorkoutTemplate> templates;
  final Function(DateTime date) onAddWorkout;
  final Function(Workout workout) onEditWorkout;
  final Function(int date) onDeleteWorkout;

  const CalendarScreen({
    super.key,
    required this.pastWorkouts,
    required this.schedule,
    required this.templates,
    required this.onAddWorkout,
    required this.onEditWorkout,
    required this.onDeleteWorkout,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
  }

  void _changeMonth(int increment) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + increment, 1);
    });
  }

  void _openDayEditor(DateTime date) {
    final workoutForDay = widget.pastWorkouts.firstWhere(
          (w) => DateTime.fromMillisecondsSinceEpoch(w.date).toDateString() == date.toDateString(),
      orElse: () => Workout(date: 0, exercises: []),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                MaterialLocalizations.of(context).formatFullDate(date),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              if (workoutForDay.date != 0) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onEditWorkout(workoutForDay);
                  },
                  child: const Text('Upravit trénink'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onDeleteWorkout(workoutForDay.date);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Smazat trénink'),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onAddWorkout(date);
                  },
                  child: const Text('Přidat trénink'),
                ),
              ],
              const SizedBox(height: 10),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zrušit'))
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildCalendar(),
    );
  }

  Widget _buildCalendar() {
    final month = _currentDate.month;
    final year = _currentDate.year;

    final firstDayOfMonth = DateTime(year, month, 1).weekday;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
            Text(
              MaterialLocalizations.of(context).formatMonthYear(_currentDate),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.8, // Upravíme poměr stran pro více textu
          ),
          itemCount: daysInMonth + firstDayOfMonth - 1,
          itemBuilder: (context, index) {
            if (index < firstDayOfMonth - 1) {
              return Container();
            }
            final day = index - firstDayOfMonth + 2;
            final date = DateTime(year, month, day);
            final workoutsOnDay = widget.pastWorkouts.where((w) => DateTime.fromMillisecondsSinceEpoch(w.date).toDateString() == date.toDateString());

            final dayOfWeek = date.weekday;
            final scheduledTemplateId = widget.schedule[dayOfWeek];
            String? scheduledPlanName;
            if (scheduledTemplateId != null) {
              scheduledPlanName = widget.templates.firstWhere((t) => t.id == scheduledTemplateId, orElse: () => WorkoutTemplate(id: '', name: '', exercises: [])).name;
            }

            return GestureDetector(
              onTap: () => _openDayEditor(date),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: workoutsOnDay.isNotEmpty ? Colors.deepPurpleAccent.withOpacity(0.8) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: date.day == DateTime.now().day && date.month == DateTime.now().month ? Colors.white : Colors.transparent)
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$day', style: TextStyle(fontWeight: workoutsOnDay.isNotEmpty ? FontWeight.bold : FontWeight.normal)),
                    if (scheduledPlanName != null && workoutsOnDay.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          scheduledPlanName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 9, color: Colors.greenAccent),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

extension DateOnlyCompare on DateTime {
  String toDateString() => toIso8601String().substring(0, 10);
}
