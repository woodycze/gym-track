import 'package:flutter/material.dart';
import '../models.dart';

class LibraryScreen extends StatefulWidget {
  final String title = 'Knihovna';
  final List<LibraryExercise> exerciseLibrary;
  final List<WorkoutTemplate> workoutTemplates;
  final Function(String name, String group, int? defaultRest) onAddExercise;
  // AKTUALIZOVANÁ DEFINICE FUNKCE
  final Function(String name, List<LibraryExercise> exercises, List<int> scheduleDays, String? templateId) onAddOrUpdateTemplate;
  final Function(String templateId) onDeleteTemplate;

  const LibraryScreen({
    super.key,
    required this.exerciseLibrary,
    required this.workoutTemplates,
    required this.onAddExercise,
    required this.onAddOrUpdateTemplate,
    required this.onDeleteTemplate,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        flexibleSpace: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Cviky'),
                Tab(text: 'Plány'),
              ],
            )
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExercisesContent(),
          _buildTemplatesContent(),
        ],
      ),
    );
  }

  Widget _buildExercisesContent() {
    final userLibraryGroups = widget.exerciseLibrary.fold<Map<String, List<LibraryExercise>>>({}, (map, ex) {
      map.putIfAbsent(ex.group, () => []).add(ex);
      return map;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Přidat vlastní cvik'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _showAddCustomExerciseDialog(),
          ),
          const SizedBox(height: 24),
          Text('Tvoje knihovna', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (userLibraryGroups.isEmpty)
            const Text('Knihovna je prázdná.')
          else
            ...userLibraryGroups.entries.map((entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...entry.value.map((ex) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(ex.name),
                    trailing: ex.defaultRestTime != null ? Text('${ex.defaultRestTime}s') : null,
                  ),
                )),
                const SizedBox(height: 16),
              ],
            )),
        ],
      ),
    );
  }

  Widget _buildTemplatesContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Vytvořit nový plán'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _showCreateOrEditTemplateDialog(),
          ),
          const SizedBox(height: 24),
          Text('Tvoje plány', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (widget.workoutTemplates.isEmpty)
            const Text('Zatím žádné plány.')
          else
            ...widget.workoutTemplates.map((template) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('${template.exercises.length} cviků', style: Theme.of(context).textTheme.bodySmall),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.white70), onPressed: () => _showCreateOrEditTemplateDialog(templateToEdit: template)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => widget.onDeleteTemplate(template.id)),
                      ],
                    )
                  ],
                ),
              ),
            ))
        ],
      ),
    );
  }

  void _showAddCustomExerciseDialog() {
    final nameController = TextEditingController();
    final groupController = TextEditingController();
    final restController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Přidat vlastní cvik'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Název cviku')),
            TextField(controller: groupController, decoration: const InputDecoration(labelText: 'Svalová partie')),
            TextField(controller: restController, decoration: const InputDecoration(labelText: 'Výchozí odpočinek (s)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Zrušit')),
          ElevatedButton(onPressed: () {
            if (nameController.text.isNotEmpty) {
              final restSeconds = int.tryParse(restController.text);
              widget.onAddExercise(
                nameController.text,
                groupController.text.isNotEmpty ? groupController.text : 'Ostatní',
                restSeconds,
              );
              Navigator.of(context).pop();
            }
          }, child: const Text('Uložit')),
        ],
      ),
    );
  }

  void _showCreateOrEditTemplateDialog({WorkoutTemplate? templateToEdit}) {
    final isEditing = templateToEdit != null;
    final nameController = TextEditingController(text: isEditing ? templateToEdit.name : '');
    List<LibraryExercise> selectedExercises = isEditing
        ? widget.exerciseLibrary.where((libEx) => templateToEdit.exercises.any((tEx) => tEx.name == libEx.name)).toList()
        : [];
    // NOVÁ LOGIKA PRO VÝBĚR DNŮ
    List<int> selectedDays = isEditing ? List<int>.from(templateToEdit.scheduleDays) : [];
    final weekDays = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Upravit plán' : 'Vytvořit plán'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Název plánu')),
                  const SizedBox(height: 24),
                  const Text('Opakovat ve dnech:'),
                  const SizedBox(height: 8),
                  // NOVÝ WIDGET PRO VÝBĚR DNŮ
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: List<Widget>.generate(7, (int index) {
                      final dayIndex = index + 1;
                      return ChoiceChip(
                        label: Text(weekDays[index]),
                        selected: selectedDays.contains(dayIndex),
                        onSelected: (bool selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedDays.add(dayIndex);
                            } else {
                              selectedDays.remove(dayIndex);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Vyber cviky:'),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.exerciseLibrary.length,
                      itemBuilder: (context, index) {
                        final exercise = widget.exerciseLibrary[index];
                        final isSelected = selectedExercises.any((e) => e.id == exercise.id);
                        return CheckboxListTile(
                          title: Text(exercise.name),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedExercises.add(exercise);
                              } else {
                                selectedExercises.removeWhere((e) => e.id == exercise.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Zrušit')),
              ElevatedButton(onPressed: () {
                if (nameController.text.isNotEmpty && selectedExercises.isNotEmpty) {
                  widget.onAddOrUpdateTemplate(
                    nameController.text,
                    selectedExercises,
                    selectedDays, // PŘEDÁNÍ VYBRANÝCH DNŮ
                    isEditing ? templateToEdit.id : null,
                  );
                  Navigator.of(context).pop();
                }
              }, child: Text(isEditing ? 'Uložit změny' : 'Vytvořit')),
            ],
          );
        },
      ),
    );
  }
}
