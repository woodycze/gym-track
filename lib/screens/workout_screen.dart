import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/animated_workout_card.dart';
import '../widgets/rest_timer_widget.dart';
import '../widgets/exercise_selector.dart';

class WorkoutScreen extends StatefulWidget {
  final String title = 'Trénink';
  final List<Exercise> currentWorkout;
  final List<LibraryExercise> exerciseLibrary;
  final List<WorkoutTemplate> workoutTemplates;
  final List<Workout> pastWorkouts;
  final int? editingDate;
  final List<AppNotification> notifications;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final Function(List<Exercise>) onUpdateWorkout;
  final Function(String) onDismissNotification;
  final Profile profile;

  const WorkoutScreen({
    super.key,
    required this.currentWorkout,
    required this.exerciseLibrary,
    required this.workoutTemplates,
    required this.pastWorkouts,
    this.editingDate,
    required this.notifications,
    required this.onSave,
    required this.onCancel,
    required this.onUpdateWorkout,
    required this.onDismissNotification,
    required this.profile,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with SingleTickerProviderStateMixin {
  Timer? _restTimer;
  int _restDurationInSeconds = 90; // Výchozí délka odpočinku
  int _currentRestSeconds = 0; // Aktuální odpočet
  late AnimationController _fabAnimationController;
  int _completedSets = 0;
  int _totalSets = 0;
  bool _useCircularTimer = false;

  // Přidám proměnnou pro RPE (subjektivní náročnost) ke každému cviku
  Map<String, int> _exerciseRPE = {};

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _calculateProgress();
  }

  @override
  void didUpdateWidget(WorkoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentWorkout != widget.currentWorkout) {
      _calculateProgress();
    }
  }

  void _calculateProgress() {
    _completedSets = 0;
    _totalSets = 0;

    for (var exercise in widget.currentWorkout) {
      for (var set in exercise.sets) {
        _totalSets++;
        if (set.done) _completedSets++;
      }
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    // Pojistka, aby se časovač nespustil s nulovou nebo zápornou hodnotou
    if (_restDurationInSeconds <= 0) return;

    setState(() {
      _currentRestSeconds = _restDurationInSeconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentRestSeconds > 0) {
        setState(() {
          _currentRestSeconds--;
        });
      } else {
        timer.cancel();
        // Zde můžeme v budoucnu přidat zvukové upozornění
      }
    });
  }

  void _showSetRestTimeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              title: Text(
                'Nastavit délku odpočinku', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const Divider(height: 1),
            ...[30, 60, 90, 120, 180].map((seconds) => ListTile(
              leading: Icon(
                Icons.timer,
                color: _restDurationInSeconds == seconds ? Theme.of(context).primaryColor : null,
              ),
              title: Text('$seconds sekund'),
              selected: _restDurationInSeconds == seconds,
              selectedColor: Theme.of(context).primaryColor,
              onTap: () {
                setState(() {
                  _restDurationInSeconds = seconds;
                });
                _startRestTimer();
                Navigator.pop(context);
              },
            )),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Vlastní čas...'),
              onTap: () {
                Navigator.pop(context);
                _showCustomRestTimeDialog();
              },
            ),
            // Nová volba pro přepínání vzhledu časovače
            SwitchListTile(
              title: const Text('Kruhový časovač'),
              value: _useCircularTimer,
              onChanged: (value) {
                setState(() {
                  _useCircularTimer = value;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showCustomRestTimeDialog() {
    final restController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zadat vlastní odpočinek'),
        content: TextField(
          controller: restController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Sekundy'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Zrušit')),
          ElevatedButton(
            onPressed: () {
              final seconds = int.tryParse(restController.text);
              if (seconds != null && seconds > 0) {
                setState(() {
                  _restDurationInSeconds = seconds;
                });
                _startRestTimer();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Nastavit'),
          ),
        ],
      ),
    );
  }

  void _addExercise(LibraryExercise exercise) {
    setState(() {
      // POUŽITÍ VÝCHOZÍHO ČASU Z KNIHOVNY
      if (exercise.defaultRestTime != null && exercise.defaultRestTime! > 0) {
        _restDurationInSeconds = exercise.defaultRestTime!;
      }

      widget.currentWorkout.add(Exercise(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: exercise.name,
        notes: '', // už žádné automatické doporučení v notes
        sets: [ExerciseSet(weight: 50, reps: 8, done: false)],
      ));
    });
    widget.onUpdateWorkout(widget.currentWorkout);
    _calculateProgress();
    Navigator.of(context).pop();
  }

  void _loadTemplate(WorkoutTemplate template) {
    setState(() {
      widget.currentWorkout.clear();
      widget.currentWorkout.addAll(template.exercises.map((e) => Exercise(
          id: DateTime.now().millisecondsSinceEpoch.toString() + e.name,
          name: e.name,
          notes: '', // už žádné automatické doporučení v notes
          sets: e.sets.map((s) => ExerciseSet(weight: s.weight, reps: s.reps, done: false)).toList()
      )));
    });
    widget.onUpdateWorkout(widget.currentWorkout);
    _calculateProgress();
    Navigator.of(context).pop();
  }

  void _showAddExerciseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Přidat cvik',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              Expanded(
                child: ExerciseSelector(
                  exerciseLibrary: widget.exerciseLibrary,
                  onExerciseSelected: _addExercise,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoadTemplateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text(
            'Načíst plán tréninku',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.workoutTemplates.isEmpty
                ? const Center(child: Text('Zatím nemáte žádné plány.'))
                : ListView.builder(
                    itemCount: widget.workoutTemplates.length,
                    itemBuilder: (context, index) {
                      final template = widget.workoutTemplates[index];
                      return ListTile(
                        leading: const Icon(Icons.fitness_center),
                        title: Text(template.name),
                        subtitle: Text('${template.exercises.length} cviků'),
                        onTap: () => _loadTemplate(template),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Inteligentní kouč pro doporučení váhy/opakování s konkrétním deload doporučením
  String getSmartSuggestion(String exerciseName) {
    final goal = widget.profile.goal;
    final exercise = widget.currentWorkout.firstWhere((e) => e.name == exerciseName, orElse: () => Exercise(id: '', name: '', sets: []));
    final rpe = _exerciseRPE[exercise.id];
    final pastPerformances = <Exercise>[];
    for (var workout in widget.pastWorkouts.reversed) {
      try {
        final ex = workout.exercises.firstWhere((ex) => ex.name == exerciseName);
        pastPerformances.add(ex);
      } catch (e) {}
    }

    if (pastPerformances.isEmpty) {
      return "První trénink tohoto cviku. Začni konzervativně a sleduj, jak se cítíš!";
    }

    // --- Nová logika: analyzujeme trend 5 tréninků, průměrná váha i opakování ---
    final trendCount = pastPerformances.length >= 5 ? 5 : pastPerformances.length;
    final lastN = pastPerformances.take(trendCount).toList();
    List<double> avgWeights = [];
    List<double> avgReps = [];
    for (var perf in lastN) {
      if (perf.sets.isNotEmpty) {
        avgWeights.add(perf.sets.map((s) => s.weight).reduce((a, b) => a + b) / perf.sets.length);
        avgReps.add(perf.sets.map((s) => s.reps).reduce((a, b) => a + b) / perf.sets.length);
      }
    }
    // Pokud je méně než 2 záznamy, doporučuj opatrnost
    if (avgWeights.length < 2 || avgReps.length < 2) {
      return "Zatím máš málo záznamů. Sleduj, jak se cítíš a postupuj opatrně.";
    }
    // Zjisti trend váhy a opakování
    bool weightStagnates = avgWeights.every((w) => (w - avgWeights[0]).abs() < 0.01);
    bool repsStagnate = avgReps.every((r) => (r - avgReps[0]).abs() < 0.01);
    bool weightDecreases = true;
    bool repsDecrease = true;
    for (int i = 1; i < avgWeights.length; i++) {
      if (avgWeights[i] >= avgWeights[i - 1]) weightDecreases = false;
      if (avgReps[i] >= avgReps[i - 1]) repsDecrease = false;
    }
    bool weightIncreases = true;
    bool repsIncrease = true;
    for (int i = 1; i < avgWeights.length; i++) {
      if (avgWeights[i] <= avgWeights[i - 1]) weightIncreases = false;
      if (avgReps[i] <= avgReps[i - 1]) repsIncrease = false;
    }
    // Personalizované doporučení
    if (weightStagnates && repsStagnate && trendCount == 5) {
      return "Stagnace: 5x stejný průměr váhy i opakování. Zvaž změnu tréninku nebo schématu!";
    }
    if (weightDecreases || repsDecrease) {
      return "Pokles výkonu: Průměrná váha nebo opakování klesají. Doporučuji deload nebo více regenerace!";
    }
    if (weightIncreases || repsIncrease) {
      return "Progres: Průměrná váha nebo opakování rostou. Jen tak dál! Pokud se cítíš dobře, můžeš zkusit přidat váhu nebo opakování.";
    }
    // Výchozí doporučení
    return "Pokračuj v progresi! Sleduj, jak se cítíš a přizpůsob trénink. Pokud stagnuješ, zvaž změnu schématu nebo deload.";
  }

  @override
  Widget build(BuildContext context) {
    // Aktualizovat stav FAB animace podle dokončených setů
    if (_totalSets > 0 && _completedSets == _totalSets) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.editingDate != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Úprava tréninku pro: ${MaterialLocalizations.of(context).formatFullDate(DateTime.fromMillisecondsSinceEpoch(widget.editingDate!))}',
                              style: TextStyle(color: Theme.of(context).primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Zobrazení notifikací
                ...widget.notifications.map((n) => Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.amber.shade800.withOpacity(0.2),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.amber),
                    title: Text(n.message, style: const TextStyle(color: Colors.white)),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => widget.onDismissNotification(n.id),
                    ),
                  ),
                )),

                // Tlačítka pro přidání cviku a načtení plánu
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Přidat cvik'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showAddExerciseModal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Načíst plán'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showLoadTemplateModal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Indikátor průběhu tréninku
                if (widget.currentWorkout.isNotEmpty && _totalSets > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Průběh tréninku', 
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(
                            '$_completedSets / $_totalSets sérií',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _totalSets > 0 ? _completedSets / _totalSets : 0,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),

                if (widget.currentWorkout.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Začni přidáním cviku',
                          style: TextStyle(fontSize: 18, color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                else
                  ...widget.currentWorkout.asMap().entries.map((entry) {
                    int exerciseIndex = entry.key;
                    Exercise exercise = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedWorkoutCard(
                          exercise: exercise,
                          onDelete: () {
                            setState(() {
                              widget.currentWorkout.removeAt(exerciseIndex);
                              widget.onUpdateWorkout(widget.currentWorkout);
                              _calculateProgress();
                            });
                          },
                          onSetsChanged: (updatedSets) {
                            setState(() {
                              exercise.sets = updatedSets;
                              widget.onUpdateWorkout(widget.currentWorkout);
                              _calculateProgress();
                            });

                            // Pokud byla série označena jako dokončená, spustíme časovač
                            if (updatedSets.any((s) => s.done)) {
                              _startRestTimer();
                            }
                          },
                        ),
                        // Kouč doporučuje
                        Container(
                          margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.psychology, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  getSmartSuggestion(exercise.name),
                                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Zadání subjektivní náročnosti (RPE)
                        Row(
                          children: [
                            const SizedBox(width: 16),
                            const Text('Náročnost (RPE):', style: TextStyle(fontSize: 13, color: Colors.white70)),
                            const SizedBox(width: 8),
                            DropdownButton<int>(
                              value: _exerciseRPE[exercise.id],
                              items: List.generate(10, (i) => i + 1).map((rpe) => DropdownMenuItem(
                                value: rpe,
                                child: Text(rpe.toString()),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _exerciseRPE[exercise.id] = value!;
                                });
                              },
                              dropdownColor: Colors.black,
                              style: const TextStyle(color: Colors.white),
                              underline: Container(height: 1, color: Colors.blue),
                            ),
                          ],
                        ),
                        // Původní poznámky (pokud jsou)
                        if (exercise.notes.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
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
                                    exercise.notes, 
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic, 
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }),
              ],
            ),
          ),

          // Časovač odpočinku
          if (_restTimer != null && _restTimer!.isActive)
            _useCircularTimer 
              ? CircularRestTimerWidget(
                  currentRestSeconds: _currentRestSeconds,
                  totalRestSeconds: _restDurationInSeconds,
                  onTimerTap: _showSetRestTimeModal,
                  onCancelTimer: () {
                    _restTimer?.cancel();
                    setState(() {});
                  },
                )
              : RestTimerWidget(
                  currentRestSeconds: _currentRestSeconds,
                  totalRestSeconds: _restDurationInSeconds,
                  onTimerTap: _showSetRestTimeModal,
                  onCancelTimer: () {
                    _restTimer?.cancel();
                    setState(() {});
                  },
                ),
        ],
      ),
      // Floating Action Button pro uložení tréninku s animací
      floatingActionButton: widget.currentWorkout.isNotEmpty 
        ? Padding(
            padding: EdgeInsets.only(
              bottom: (_restTimer != null && _restTimer!.isActive) ? 80.0 : 0.0,
            ),
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 1.0,
                end: 1.1,
              ).animate(
                CurvedAnimation(
                  parent: _fabAnimationController,
                  curve: Curves.elasticInOut,
                ),
              ),
              child: FloatingActionButton.extended(
                icon: const Icon(Icons.check),
                label: const Text('Uložit trénink'),
                backgroundColor: _completedSets == _totalSets && _totalSets > 0
                  ? Colors.green
                  : Theme.of(context).primaryColor,
                onPressed: widget.onSave,
              ),
            ),
          )
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: widget.editingDate != null ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextButton(
            onPressed: widget.onCancel,
            child: const Text('Zrušit úpravy'),
          ),
        ),
      ) : null,
    );
  }
}
