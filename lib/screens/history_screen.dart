import 'package:flutter/material.dart';
import '../models.dart';

class HistoryScreen extends StatelessWidget {
  final String title = 'Historie';
  final List<Workout> pastWorkouts;

  const HistoryScreen({super.key, required this.pastWorkouts});

  @override
  Widget build(BuildContext context) {
    final sortedWorkouts = [...pastWorkouts]..sort((a, b) => b.date.compareTo(a.date));

    return sortedWorkouts.isEmpty
        ? const Center(child: Text('Zatím žádné uložené tréninky.'))
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedWorkouts.length,
      itemBuilder: (context, index) {
        final workout = sortedWorkouts[index];
        final date = DateTime.fromMillisecondsSinceEpoch(workout.date);
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MaterialLocalizations.of(context).formatFullDate(date),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor),
                ),
                const Divider(height: 20),
                ...workout.exercises.map((ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.name, style: Theme.of(context).textTheme.titleLarge),
                      if (ex.notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                          child: Text('"${ex.notes}"', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                        ),
                      ...ex.sets.map((set) => Text(
                        '  - ${set.weight} kg x ${set.reps} opakování ${set.done ? "✓" : ""}',
                        style: TextStyle(color: set.done ? Colors.greenAccent : Colors.grey),
                      ))
                    ],
                  ),
                ))
              ],
            ),
          ),
        );
      },
    );
  }
}
