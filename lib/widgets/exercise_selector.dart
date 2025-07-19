import 'package:flutter/material.dart';
import '../models.dart';

class ExerciseSelector extends StatefulWidget {
  final List<LibraryExercise> exerciseLibrary;
  final Function(LibraryExercise) onExerciseSelected;

  const ExerciseSelector({
    super.key,
    required this.exerciseLibrary,
    required this.onExerciseSelected,
  });

  @override
  State<ExerciseSelector> createState() => _ExerciseSelectorState();
}

class _ExerciseSelectorState extends State<ExerciseSelector> {
  String _searchQuery = '';
  String _selectedGroup = 'Vše';

  @override
  Widget build(BuildContext context) {
    // Získat všechny skupiny cviků
    final groups = ['Vše', ...widget.exerciseLibrary.map((e) => e.group).toSet().toList()..sort()];

    // Filtrovat cviky podle vyhledávání a skupiny
    final filteredExercises = widget.exerciseLibrary.where((exercise) {
      final matchesSearch = _searchQuery.isEmpty ||
          exercise.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGroup = _selectedGroup == 'Vše' || exercise.group == _selectedGroup;
      return matchesSearch && matchesGroup;
    }).toList();

    // Seřadit cviky podle názvu
    filteredExercises.sort((a, b) => a.name.compareTo(b.name));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Hledat cvik...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: groups.map((group) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(group),
                selected: _selectedGroup == group,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedGroup = group;
                    });
                  }
                },
                backgroundColor: Colors.black.withOpacity(0.3),
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.7),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredExercises.isEmpty
              ? Center(child: Text(
                  _searchQuery.isEmpty
                      ? 'Žádné cviky v této kategorii.'
                      : 'Žádné výsledky pro "$_searchQuery".',
                  style: TextStyle(color: Colors.white70),
                ))
              : ListView.builder(
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
                    return ListTile(
                      title: Text(exercise.name),
                      subtitle: Text(exercise.group),
                      trailing: exercise.defaultRestTime != null 
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('${exercise.defaultRestTime}s', style: TextStyle(color: Colors.grey)),
                              ],
                            )
                          : null,
                      onTap: () {
                        widget.onExerciseSelected(exercise);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
