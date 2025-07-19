import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:math';
import 'models.dart';
import 'screens/dashboard_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/history_screen.dart';
import 'screens/library_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';
import 'theme.dart';
import 'database_helper.dart';
import 'notification_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Tracker',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('cs', ''),
        Locale('en', ''),
      ],
      locale: const Locale('cs'),
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isWorkoutActive = false;
  late PageController _pageController;
  late AnimationController _fabAnimationController;

  // --- STAV APLIKACE ---
  List<Workout> _pastWorkouts = [];
  List<LibraryExercise> _exerciseLibrary = [];
  List<WorkoutTemplate> _workoutTemplates = [];
  Map<int, String> _schedule = {};
  List<Exercise> _currentWorkout = [];
  int? _editingDate;
  List<AppNotification> _notifications = [];
  List<WeightEntry> _weightHistory = [];
  Profile _profile = Profile();

  // Nové proměnné pro sledování deloadu
  int _workoutsSinceDeload = 0;
  DateTime? _lastWorkoutDate;
  
  // Databáze a notifikace
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _notificationService.initialize();
    await _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Načtení dat z databáze
      final workouts = await _databaseHelper.getWorkouts();
      final exercises = await _databaseHelper.getLibraryExercises();
      final templates = await _databaseHelper.getWorkoutTemplates();
      final weightHistory = await _databaseHelper.getWeightEntries();
      final profile = await _databaseHelper.getProfile();
      
      setState(() {
        _pastWorkouts = workouts;
        _exerciseLibrary = exercises;
        _workoutTemplates = templates;
        _weightHistory = weightHistory;
        if (profile != null) {
          _profile = profile;
        }
        
        // Inicializace rozvrhu
        _schedule = {};
        for (var template in _workoutTemplates) {
          for (var day in template.scheduleDays) {
            _schedule[day] = template.id;
          }
        }
        
        // Inicializace počítadla deloadu
        _workoutsSinceDeload = _pastWorkouts.length;
        if (_pastWorkouts.isNotEmpty) {
          _lastWorkoutDate = DateTime.fromMillisecondsSinceEpoch(_pastWorkouts.last.date);
        }
      });
      
      // Pokud je databáze prázdná, načti výchozí data
      if (_pastWorkouts.isEmpty) {
        _loadDefaultData();
      }
    } catch (e) {
      // Fallback na výchozí data při chybě
      _loadDefaultData();
    }
  }

  void _loadDefaultData() {
    setState(() {
      _pastWorkouts = [
        Workout(date: DateTime.now().subtract(const Duration(days: 35)).millisecondsSinceEpoch, exercises: [Exercise(id: '1', name: 'Bench Press', sets: [ExerciseSet(weight: 100, reps: 5)])]),
        Workout(date: DateTime.now().subtract(const Duration(days: 28)).millisecondsSinceEpoch, exercises: [Exercise(id: '1', name: 'Bench Press', sets: [ExerciseSet(weight: 102.5, reps: 5)])]),
        Workout(date: DateTime.now().subtract(const Duration(days: 21)).millisecondsSinceEpoch, exercises: [Exercise(id: '1', name: 'Bench Press', sets: [ExerciseSet(weight: 105, reps: 5)])]),
        Workout(date: DateTime.now().subtract(const Duration(days: 14)).millisecondsSinceEpoch, exercises: [Exercise(id: '1', name: 'Bench Press', sets: [ExerciseSet(weight: 105, reps: 4)])]),
        Workout(date: DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch, exercises: [Exercise(id: '1', name: 'Bench Press', sets: [ExerciseSet(weight: 102.5, reps: 5)])]),
      ];
      _exerciseLibrary = [
        LibraryExercise(id: '1', name: 'Bench Press', group: 'Prsa', defaultRestTime: 120),
        LibraryExercise(id: '2', name: 'Dřep', group: 'Nohy', defaultRestTime: 180),
        LibraryExercise(id: '3', name: 'Mrtvý tah', group: 'Záda'),
      ];
      _workoutTemplates = [
        WorkoutTemplate(id: 't1', name: 'Full Body A', exercises: [
          Exercise(id: 't1e1', name: 'Dřep', sets: [ExerciseSet(weight: 100, reps: 5)]),
          Exercise(id: 't1e2', name: 'Bench Press', sets: [ExerciseSet(weight: 80, reps: 8)]),
        ], scheduleDays: [1, 4])
      ];
    });
  }

  void _startWorkoutForDate(DateTime date, {List<Exercise>? templateExercises}) {
    setState(() {
      _editingDate = date.millisecondsSinceEpoch;
      _currentWorkout = templateExercises ?? [];
      _isWorkoutActive = true;
    });
  }

  void _editWorkout(Workout workout) {
    setState(() {
      _editingDate = workout.date;
      _currentWorkout = List<Exercise>.from(workout.exercises.map(
              (ex) => Exercise.clone(ex)
      ));
      _isWorkoutActive = true;
    });
  }

  void _deleteWorkout(int date) {
    setState(() {
      _pastWorkouts.removeWhere((w) => w.date == date);
    });
  }

  Future<void> _saveWorkout() async {
    final dateToSave = _editingDate ?? DateTime.now().millisecondsSinceEpoch;
    final now = DateTime.fromMillisecondsSinceEpoch(dateToSave);

    // Reset počítadla deloadu, pokud byla pauza delší než 10 dní
    if (_lastWorkoutDate != null && now.difference(_lastWorkoutDate!).inDays > 10) {
      _workoutsSinceDeload = 0;
    }
    _workoutsSinceDeload++;
    _lastWorkoutDate = now;

    final workout = Workout(date: dateToSave, exercises: _currentWorkout);
    
    try {
      // Uložení do databáze
      await _databaseHelper.insertWorkout(workout);
      
      // Aktualizace UI
      setState(() {
        _pastWorkouts.removeWhere((w) => DateTime.fromMillisecondsSinceEpoch(w.date).toIso8601String().substring(0, 10) == now.toIso8601String().substring(0, 10));
        _pastWorkouts.add(workout);
        _pastWorkouts.sort((a, b) => a.date.compareTo(b.date)); // Udržujeme seřazeno

        _currentWorkout = [];
        _editingDate = null;
        _isWorkoutActive = false;
        _selectedIndex = 2;
      });

      // Zobrazení notifikace o dokončení
      await _notificationService.showWorkoutCompletedNotification();
      
      _checkForDeloadSuggestion();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Text('Trénink úspěšně uložen!'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.green.shade800,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 16),
              Text('Chyba při ukládání tréninku'),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _cancelWorkout() {
    // Zobrazit potvrzovací dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zrušit trénink?'),
        content: const Text('Opravdu chcete zrušit tento trénink? Všechny změny budou ztraceny.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ne'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentWorkout = [];
                _editingDate = null;
                _isWorkoutActive = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Ano, zrušit'),
          ),
        ],
      ),
    );
  }

  void _addExerciseToLibrary(String name, String group, int? defaultRest) {
    setState(() {
      _exerciseLibrary.add(LibraryExercise(
        id: DateTime.now().toString(),
        name: name,
        group: group,
        defaultRestTime: defaultRest,
      ));
    });

    // Poskytnutí zpětné vazby
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cvik "$name" byl přidán do knihovny'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _addOrUpdateTemplate(String name, List<LibraryExercise> exercises, List<int> scheduleDays, String? templateId) {
    setState(() {
      String currentTemplateId;
      bool isNew = templateId == null;

      if (templateId != null) {
        final index = _workoutTemplates.indexWhere((t) => t.id == templateId);
        if (index != -1) {
          _workoutTemplates[index].name = name;
          _workoutTemplates[index].exercises = exercises.map((ex) => Exercise(id: ex.id, name: ex.name, sets: [ExerciseSet(weight: 50, reps: 8)])).toList();
          _workoutTemplates[index].scheduleDays = scheduleDays;
        }
        currentTemplateId = templateId;
      } else {
        final newTemplate = WorkoutTemplate(
          id: DateTime.now().toString(),
          name: name,
          exercises: exercises.map((ex) => Exercise(id: ex.id, name: ex.name, sets: [ExerciseSet(weight: 50, reps: 8)])).toList(),
          scheduleDays: scheduleDays,
        );
        _workoutTemplates.add(newTemplate);
        currentTemplateId = newTemplate.id;
      }
      _schedule.removeWhere((key, value) => value == currentTemplateId);
      for (var day in scheduleDays) {
        _schedule[day] = currentTemplateId;
      }

      // Poskytnutí zpětné vazby
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNew 
            ? 'Plán "$name" byl vytvořen' 
            : 'Plán "$name" byl aktualizován'
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    });
  }

  void _deleteTemplate(String templateId) {
    // Najít název plánu před smazáním
    final templateName = _workoutTemplates.firstWhere((t) => t.id == templateId).name;

    setState(() {
      _workoutTemplates.removeWhere((t) => t.id == templateId);
      _schedule.removeWhere((key, value) => value == templateId);
    });

    // Poskytnutí zpětné vazby
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plán "$templateName" byl smazán'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Zpět',
          onPressed: () {
            // Implementovat funkci undo, pokud je potřeba
          },
        ),
      ),
    );
  }

  // VYLEPŠENÁ METODA PRO KONTROLU A DOPORUČENÍ DELOADU
  void _checkForDeloadSuggestion() {
    // Zabrání zobrazení více stejných notifikací
    if (_notifications.any((n) => n.type == 'deload_suggestion')) return;

    // Pravidlo 1: Detekce podle počtu tréninků
    const int workoutCountThreshold = 18;
    if (_workoutsSinceDeload >= workoutCountThreshold) {
      _addDeloadNotification('Počet tréninků', 'Máš za sebou $_workoutsSinceDeload tréninků. Je čas na deload pro maximální progres!');
      return; // Pokud je toto pravidlo splněno, dál nekontrolujeme
    }

    // Pravidlo 2: Detekce podle výkonnostní metriky (stagnace)
    const List<String> keyExercises = ['Bench Press', 'Dřep', 'Mrtvý tah'];
    const int workoutsToAnalyze = 3; // Analyzujeme poslední 3 výkony

    for (var exerciseName in keyExercises) {
      // Najdeme všechny minulé tréninky obsahující daný cvik
      final relevantWorkouts = _pastWorkouts
          .where((w) => w.exercises.any((e) => e.name == exerciseName))
          .toList();

      if (relevantWorkouts.length >= workoutsToAnalyze) {
        // Vezmeme posledních N tréninků
        final lastNWorkouts = relevantWorkouts.sublist(relevantWorkouts.length - workoutsToAnalyze);

        // Získáme nejlepší set (max váha) z každého z těchto tréninků
        final topSets = lastNWorkouts.map((w) {
          final exercise = w.exercises.firstWhere((e) => e.name == exerciseName);
          return exercise.sets.reduce((a, b) => a.weight > b.weight ? a : b);
        }).toList();

        // Zkontrolujeme stagnaci nebo regresi
        final latestSet = topSets[workoutsToAnalyze - 1];
        final previousSet = topSets[workoutsToAnalyze - 2];

        if (latestSet.weight <= previousSet.weight) {
          _addDeloadNotification('Stagnace výkonu', 'Zdá se, že u cviku "$exerciseName" stagnuješ. Zvaž deload, aby ses posunul dál.');
          return; // Našli jsme stagnaci, ukončíme
        }
      }
    }
  }

  void _addDeloadNotification(String reason, String message) {
    setState(() {
      // Odstraníme starou notifikaci, pokud existuje, abychom ji nahradili novou
      _notifications.removeWhere((n) => n.type == 'deload_suggestion');
      _notifications.add(AppNotification(
        id: DateTime.now().toString(),
        type: 'deload_suggestion',
        message: message,
        date: DateTime.now().millisecondsSinceEpoch,
      ));
    });
  }


  void _dismissNotification(String id) {
    setState(() {
      final notification = _notifications.firstWhere((n) => n.id == id);
      // Pokud uživatel zavře notifikaci na deload, resetujeme počítadlo,
      // aby se mu deload mohl navrhnout znovu na základě budoucího výkonu.
      if (notification.type == 'deload_suggestion') {
        _workoutsSinceDeload = 0;
      }
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    if (index == 0) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  void _onPageChanged(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    if (index == 0) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> mainScreens = <Widget>[
      DashboardScreen(
        schedule: _schedule,
        templates: _workoutTemplates,
        pastWorkouts: _pastWorkouts,
        onStartWorkout: _startWorkoutForDate,
      ),
      CalendarScreen(
        pastWorkouts: _pastWorkouts,
        schedule: _schedule,
        templates: _workoutTemplates,
        onAddWorkout: _startWorkoutForDate,
        onEditWorkout: _editWorkout,
        onDeleteWorkout: _deleteWorkout,
      ),
      StatisticsScreen(
        workouts: _pastWorkouts,
        weightHistory: _weightHistory,
      ),
      LibraryScreen(
        exerciseLibrary: _exerciseLibrary,
        workoutTemplates: _workoutTemplates,
        onAddExercise: _addExerciseToLibrary,
        onAddOrUpdateTemplate: _addOrUpdateTemplate,
        onDeleteTemplate: _deleteTemplate,
      ),
      ProfileScreen(pastWorkouts: _pastWorkouts),
    ];

    final String currentTitle = _isWorkoutActive
        ? 'Trénink'
        : (mainScreens[_selectedIndex] as dynamic).title;

    final Widget quickStartFAB = ScaleTransition(
      scale: Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(_fabAnimationController),
      child: FloatingActionButton(
        onPressed: () => _startWorkoutForDate(DateTime.now()),
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.fitness_center),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          if (_selectedIndex == 4 && !_isWorkoutActive) // Na obrazovce profilu
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      profile: _profile,
                      onProfileUpdate: (profile) {
                        setState(() {
                          _profile = profile;
                        });
                      },
                      onDataExport: () {
                        // Implementace exportu dat
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Export dat bude brzy dostupný')),
                        );
                      },
                      onDataImport: () {
                        // Implementace importu dat
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Import dat bude brzy dostupný')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          if (_selectedIndex == 3 && !_isWorkoutActive) // Na obrazovce knihovny
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Rychlé přidání cviku nebo plánu
              },
            ),
        ],
      ),
      body: _isWorkoutActive
          ? WorkoutScreen(
              key: ValueKey(_editingDate),
              currentWorkout: _currentWorkout,
              exerciseLibrary: _exerciseLibrary,
              workoutTemplates: _workoutTemplates,
              pastWorkouts: _pastWorkouts,
              editingDate: _editingDate,
              notifications: _notifications,
              onSave: _saveWorkout,
              onCancel: _cancelWorkout,
              onUpdateWorkout: (updatedWorkout) {
                setState(() {
                  _currentWorkout = updatedWorkout;
                });
              },
              onDismissNotification: _dismissNotification,
            )
          : PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const CustomPageViewScrollPhysics(),
              children: mainScreens,
            ),
      floatingActionButton: _selectedIndex == 0 && !_isWorkoutActive ? quickStartFAB : null,
      bottomNavigationBar: _isWorkoutActive ? null : Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Přehled'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Kalendář'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Statistiky'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Knihovna'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}

// Vlastní fyzika pro PageView
class CustomPageViewScrollPhysics extends ScrollPhysics {
  const CustomPageViewScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  CustomPageViewScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageViewScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 80,
        stiffness: 100,
        damping: 1.0,
      );
}
