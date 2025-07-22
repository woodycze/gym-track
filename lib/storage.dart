import 'models.dart';
import 'database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Abstrakce úložiště
abstract class WorkoutStorage {
  Future<void> insertWorkout(Workout workout);
  Future<List<Workout>> getWorkouts();
  // Nové metody pro web
  Future<void> saveLibraryExercises(List<LibraryExercise> exercises);
  Future<List<LibraryExercise>> getLibraryExercises();
  Future<void> saveWorkoutTemplates(List<WorkoutTemplate> templates);
  Future<List<WorkoutTemplate>> getWorkoutTemplates();
  Future<void> saveProfile(Profile profile);
  Future<Profile?> getProfile();
  // Nové pro váhovou historii
  Future<void> saveWeightHistory(List<WeightEntry> entries);
  Future<List<WeightEntry>> getWeightHistory();
}

// --- Implementace pro Firestore ---
class FirestoreStorage implements WorkoutStorage {
  final CollectionReference _workoutsRef = FirebaseFirestore.instance.collection('workouts');

  @override
  Future<void> insertWorkout(Workout workout) async {
    await _workoutsRef.doc(workout.date.toString()).set({
      'date': workout.date,
      'exercises': workout.exercises.map((e) => {
        'id': e.id,
        'name': e.name,
        'notes': e.notes,
        'supersetWith': e.supersetWith,
        'sets': e.sets.map((s) => {
          'weight': s.weight,
          'reps': s.reps,
          'done': s.done,
          'type': s.type.name,
        }).toList(),
      }).toList(),
    });
  }

  @override
  Future<List<Workout>> getWorkouts() async {
    final snapshot = await _workoutsRef.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Workout(
        date: data['date'],
        exercises: (data['exercises'] as List).map((e) => Exercise(
          id: e['id'],
          name: e['name'],
          notes: e['notes'] ?? '',
          sets: (e['sets'] as List).map((s) => ExerciseSet(
            weight: (s['weight'] as num).toDouble(),
            reps: s['reps'],
            done: s['done'] ?? false,
            type: SetType.values.firstWhere((t) => t.name == (s['type'] ?? 'normal'), orElse: () => SetType.normal),
          )).toList(),
          supersetWith: e['supersetWith'],
        )).toList(),
      );
    }).toList();
  }

  @override
  Future<void> saveLibraryExercises(List<LibraryExercise> exercises) async {
    // Firestore: knihovna cviků se spravuje přes DatabaseHelper
    // (ponech prázdné, používá se přímo DatabaseHelper)
  }
  @override
  Future<List<LibraryExercise>> getLibraryExercises() async {
    // Firestore: knihovna cviků se spravuje přes DatabaseHelper
    // (ponech prázdné, používá se přímo DatabaseHelper)
    return [];
  }
  @override
  Future<void> saveWorkoutTemplates(List<WorkoutTemplate> templates) async {}
  @override
  Future<List<WorkoutTemplate>> getWorkoutTemplates() async {
    // Firestore: šablony tréninků se spravují přes DatabaseHelper
    // (ponech prázdné, používá se přímo DatabaseHelper)
    return [];
  }
  @override
  Future<void> saveProfile(Profile profile) async {
    // Firestore: profil se spravuje přes DatabaseHelper
    // (ponech prázdné, používá se přímo DatabaseHelper)
  }
  @override
  Future<Profile?> getProfile() async {
    // Firestore: profil se spravuje přes DatabaseHelper
    // (ponech prázdné, používá se přímo DatabaseHelper)
    return null;
  }
  @override
  Future<void> saveWeightHistory(List<WeightEntry> entries) async {
    // Firestore: váhová historie se spravuje přes DatabaseHelper
    // (ponech prázdné, používá se přímo DatabaseHelper)
  }
  @override
  Future<List<WeightEntry>> getWeightHistory() async {
    // Firestore: váhová historie se spravuje přes DatabaseHelper
    // (ponech prázdné, používá se přímo DatabaseHelper)
    return [];
  }
}

// --- Implementace pro mobil (SQLite) ---
class SQLiteStorage implements WorkoutStorage {
  final DatabaseHelper _db = DatabaseHelper();
  @override
  Future<void> insertWorkout(Workout workout) => _db.insertWorkout(workout);
  @override
  Future<List<Workout>> getWorkouts() => _db.getWorkouts();
  @override
  Future<void> saveLibraryExercises(List<LibraryExercise> exercises) async {
    // Mobil: knihovna cviků se spravuje přes DatabaseHelper
    // (ponech prázdné, používá se přímo DatabaseHelper)
  }
  @override
  Future<List<LibraryExercise>> getLibraryExercises() async {
    return _db.getLibraryExercises();
  }
  @override
  Future<void> saveWorkoutTemplates(List<WorkoutTemplate> templates) async {}
  @override
  Future<List<WorkoutTemplate>> getWorkoutTemplates() async {
    return _db.getWorkoutTemplates();
  }
  @override
  Future<void> saveProfile(Profile profile) => _db.saveProfile(profile);
  @override
  Future<Profile?> getProfile() => _db.getProfile();
  @override
  Future<void> saveWeightHistory(List<WeightEntry> entries) async {}
  @override
  Future<List<WeightEntry>> getWeightHistory() => _db.getWeightEntries();
}

// --- Implementace pro web (SharedPreferences) ---
class SharedPrefsStorage implements WorkoutStorage {
  static const String _workoutsKey = 'workouts';
  static const String _exercisesKey = 'library_exercises';
  static const String _templatesKey = 'workout_templates';
  static const String _profileKey = 'profile';
  static const String _weightKey = 'weight_history';

  // --- Workouty ---
  @override
  Future<void> insertWorkout(Workout workout) async {
    final prefs = await SharedPreferences.getInstance();
    final workouts = await getWorkouts();
    workouts.removeWhere((w) => w.date == workout.date);
    workouts.add(workout);
    final jsonList = workouts.map((w) => _workoutToJson(w)).toList();
    await prefs.setString(_workoutsKey, jsonEncode(jsonList));
  }
  @override
  Future<List<Workout>> getWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_workoutsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((j) => _workoutFromJson(j)).toList();
  }

  // --- Knihovna cviků ---
  @override
  Future<void> saveLibraryExercises(List<LibraryExercise> exercises) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = exercises.map((e) => _libraryExerciseToJson(e)).toList();
    await prefs.setString(_exercisesKey, jsonEncode(jsonList));
  }
  @override
  Future<List<LibraryExercise>> getLibraryExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_exercisesKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((j) => _libraryExerciseFromJson(j)).toList();
  }

  // --- Šablony tréninků ---
  @override
  Future<void> saveWorkoutTemplates(List<WorkoutTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = templates.map((t) => _templateToJson(t)).toList();
    await prefs.setString(_templatesKey, jsonEncode(jsonList));
  }
  @override
  Future<List<WorkoutTemplate>> getWorkoutTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_templatesKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((j) => _templateFromJson(j)).toList();
  }

  // --- Profil ---
  @override
  Future<void> saveProfile(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(_profileToJson(profile)));
  }
  @override
  Future<Profile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_profileKey);
    if (jsonString == null) return null;
    final Map<String, dynamic> j = jsonDecode(jsonString);
    return _profileFromJson(j);
  }

  // --- Váhová historie ---
  @override
  Future<void> saveWeightHistory(List<WeightEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.map((e) => _weightEntryToJson(e)).toList();
    await prefs.setString(_weightKey, jsonEncode(jsonList));
  }
  @override
  Future<List<WeightEntry>> getWeightHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_weightKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((j) => _weightEntryFromJson(j)).toList();
  }

  // --- Serializace ---
  Map<String, dynamic> _workoutToJson(Workout w) => {
    'date': w.date,
    'exercises': w.exercises.map((e) => _exerciseToJson(e)).toList(),
  };
  Workout _workoutFromJson(Map<String, dynamic> j) => Workout(
    date: j['date'],
    exercises: (j['exercises'] as List).map((e) => _exerciseFromJson(e)).toList(),
  );
  Map<String, dynamic> _exerciseToJson(Exercise e) => {
    'id': e.id,
    'name': e.name,
    'notes': e.notes,
    'supersetWith': e.supersetWith,
    'sets': e.sets.map((s) => _setToJson(s)).toList(),
  };
  Exercise _exerciseFromJson(Map<String, dynamic> j) => Exercise(
    id: j['id'],
    name: j['name'],
    notes: j['notes'] ?? '',
    sets: (j['sets'] as List).map((s) => _setFromJson(s)).toList(),
    supersetWith: j['supersetWith'],
  );
  Map<String, dynamic> _setToJson(ExerciseSet s) => {
    'weight': s.weight,
    'reps': s.reps,
    'done': s.done,
    'type': s.type.name,
  };
  ExerciseSet _setFromJson(Map<String, dynamic> j) => ExerciseSet(
    weight: (j['weight'] as num).toDouble(),
    reps: j['reps'],
    done: j['done'] ?? false,
    type: SetType.values.firstWhere((t) => t.name == (j['type'] ?? 'normal'), orElse: () => SetType.normal),
  );
  Map<String, dynamic> _libraryExerciseToJson(LibraryExercise e) => {
    'id': e.id,
    'name': e.name,
    'group': e.group,
    'defaultRestTime': e.defaultRestTime,
  };
  LibraryExercise _libraryExerciseFromJson(Map<String, dynamic> j) => LibraryExercise(
    id: j['id'],
    name: j['name'],
    group: j['group'],
    defaultRestTime: j['defaultRestTime'],
  );
  Map<String, dynamic> _templateToJson(WorkoutTemplate t) => {
    'id': t.id,
    'name': t.name,
    'exercises': t.exercises.map((e) => _exerciseToJson(e)).toList(),
    'scheduleDays': t.scheduleDays,
  };
  WorkoutTemplate _templateFromJson(Map<String, dynamic> j) => WorkoutTemplate(
    id: j['id'],
    name: j['name'],
    exercises: (j['exercises'] as List).map((e) => _exerciseFromJson(e)).toList(),
    scheduleDays: (j['scheduleDays'] as List).map((d) => d as int).toList(),
  );
  Map<String, dynamic> _profileToJson(Profile p) => {
    'name': p.name,
    'age': p.age,
    'height': p.height,
    'gender': p.gender,
    'goal': p.goal,
  };
  Profile _profileFromJson(Map<String, dynamic> j) => Profile(
    name: j['name'] ?? '',
    age: j['age'] ?? '',
    height: j['height'] ?? '',
    gender: j['gender'] ?? 'Jiné',
    goal: j['goal'] ?? 'Síla',
  );
  Map<String, dynamic> _weightEntryToJson(WeightEntry e) => {
    'date': e.date.millisecondsSinceEpoch,
    'weight': e.weight,
  };
  WeightEntry _weightEntryFromJson(Map<String, dynamic> j) => WeightEntry(
    date: DateTime.fromMillisecondsSinceEpoch(j['date']),
    weight: (j['weight'] as num).toDouble(),
  );
}

// --- Factory pro multiplatformní použití ---
WorkoutStorage getWorkoutStorage() {
  if (kIsWeb) {
    return SharedPrefsStorage();
  } else {
    return SQLiteStorage();
  }
} 