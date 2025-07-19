// Tento soubor slouží jako centrální místo pro všechny naše datové struktury.

enum SetType { warmup, normal, dropset, failure }

class ExerciseSet {
  double weight;
  int reps;
  bool done;
  SetType type;
  ExerciseSet({required this.weight, required this.reps, this.done = false, this.type = SetType.normal});
}

class Exercise {
  String id;
  String name;
  String notes;
  List<ExerciseSet> sets;
  String? supersetWith;

  Exercise({
    required this.id,
    required this.name,
    this.notes = '',
    required this.sets,
    this.supersetWith,
  });

  // Klonovací metoda pro vytvoření hluboké kopie
  Exercise.clone(Exercise original)
      : id = original.id,
        name = original.name,
        notes = original.notes,
        supersetWith = original.supersetWith,
        sets = List<ExerciseSet>.from(original.sets.map((s) => ExerciseSet(weight: s.weight, reps: s.reps, done: s.done, type: s.type)));
}

class Workout {
  final int date;
  final List<Exercise> exercises;
  Workout({required this.date, required this.exercises});
}

class LibraryExercise {
  final String id;
  final String name;
  final String group;
  int? defaultRestTime;

  LibraryExercise({
    required this.id,
    required this.name,
    required this.group,
    this.defaultRestTime,
  });
}

class WorkoutTemplate {
  final String id;
  String name;
  List<Exercise> exercises;
  List<int> scheduleDays; // NOVÁ VLASTNOST: Seznam dnů (1=Po, 7=Ne)

  WorkoutTemplate({
    required this.id,
    required this.name,
    required this.exercises,
    this.scheduleDays = const [], // VÝCHOZÍ HODNOTA
  });
}

class WeightEntry {
  final DateTime date;
  final double weight;
  WeightEntry({required this.date, required this.weight});
}

class Profile {
  String age;
  String height;
  String gender;
  Profile({this.age = '', this.height = '', this.gender = 'Jiné'});
}

class AppNotification {
  final String id;
  final String type;
  final String message;
  final int date;
  AppNotification({required this.id, required this.type, required this.message, required this.date});
}
