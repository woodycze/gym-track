import 'package:flutter/material.dart';
import '../models.dart';

class AnimatedWorkoutCard extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onDelete;
  final Function(List<ExerciseSet>) onSetsChanged;

  const AnimatedWorkoutCard({
    super.key,
    required this.exercise,
    required this.onDelete,
    required this.onSetsChanged,
  });

  @override
  State<AnimatedWorkoutCard> createState() => _AnimatedWorkoutCardState();
}

class _AnimatedWorkoutCardState extends State<AnimatedWorkoutCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      child: FadeTransition(
        opacity: _animation,
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.exercise.name, style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        _controller.reverse().then((_) => widget.onDelete());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (widget.exercise.notes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, 
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.exercise.notes, 
                            style: TextStyle(
                              fontStyle: FontStyle.italic, 
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                ...widget.exercise.sets.asMap().entries.map((setEntry) {
                  int setIndex = setEntry.key;
                  ExerciseSet set = setEntry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: set.done ? Colors.green.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: set.done ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(child: Text('${setIndex + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: set.weight.toString()),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Váha (kg)',
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onChanged: (v) {
                                set.weight = double.tryParse(v) ?? 0;
                                widget.onSetsChanged(widget.exercise.sets);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: set.reps.toString()),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Opak.',
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                              onChanged: (v) {
                                set.reps = int.tryParse(v) ?? 0;
                                widget.onSetsChanged(widget.exercise.sets);
                              },
                            ),
                          ),
                          Checkbox(
                            value: set.done,
                            activeColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() => set.done = val ?? false);
                              widget.onSetsChanged(widget.exercise.sets);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Přidat sérii'),
                  onPressed: () {
                    setState(() {
                      widget.exercise.sets.add(ExerciseSet(
                        weight: widget.exercise.sets.isNotEmpty 
                            ? widget.exercise.sets.last.weight 
                            : 50,
                        reps: widget.exercise.sets.isNotEmpty 
                            ? widget.exercise.sets.last.reps 
                            : 8,
                      ));
                    });
                    widget.onSetsChanged(widget.exercise.sets);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
