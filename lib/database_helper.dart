import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'gym_track.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabulka pro tréninky
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Tabulka pro cviky
    await db.execute('''
      CREATE TABLE exercises (
        id TEXT PRIMARY KEY,
        workout_id INTEGER,
        name TEXT NOT NULL,
        notes TEXT,
        superset_with TEXT,
        FOREIGN KEY (workout_id) REFERENCES workouts (id) ON DELETE CASCADE
      )
    ''');

    // Tabulka pro série
    await db.execute('''
      CREATE TABLE exercise_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id TEXT,
        weight REAL NOT NULL,
        reps INTEGER NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        type TEXT NOT NULL DEFAULT 'normal',
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    // Tabulka pro knihovnu cviků
    await db.execute('''
      CREATE TABLE library_exercises (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        group_name TEXT NOT NULL,
        default_rest_time INTEGER
      )
    ''');

    // Tabulka pro šablony tréninků
    await db.execute('''
      CREATE TABLE workout_templates (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    // Tabulka pro cviky v šablonách
    await db.execute('''
      CREATE TABLE template_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id TEXT,
        exercise_id TEXT,
        FOREIGN KEY (template_id) REFERENCES workout_templates (id) ON DELETE CASCADE,
        FOREIGN KEY (exercise_id) REFERENCES library_exercises (id) ON DELETE CASCADE
      )
    ''');

    // Tabulka pro dny v rozvrhu
    await db.execute('''
      CREATE TABLE schedule_days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id TEXT,
        day INTEGER NOT NULL,
        FOREIGN KEY (template_id) REFERENCES workout_templates (id) ON DELETE CASCADE
      )
    ''');

    // Tabulka pro váhu
    await db.execute('''
      CREATE TABLE weight_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        weight REAL NOT NULL
      )
    ''');

    // Tabulka pro notifikace
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        message TEXT NOT NULL,
        date INTEGER NOT NULL,
        read INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabulka pro profil
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY DEFAULT 1,
        age TEXT,
        height TEXT,
        gender TEXT,
        name TEXT
      )
    ''');
  }

  // CRUD operace pro tréninky
  Future<int> insertWorkout(Workout workout) async {
    final db = await database;
    final workoutId = await db.insert('workouts', {
      'date': workout.date,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });

    for (var exercise in workout.exercises) {
      await db.insert('exercises', {
        'id': exercise.id,
        'workout_id': workoutId,
        'name': exercise.name,
        'notes': exercise.notes,
        'superset_with': exercise.supersetWith,
      });

      for (var set in exercise.sets) {
        await db.insert('exercise_sets', {
          'exercise_id': exercise.id,
          'weight': set.weight,
          'reps': set.reps,
          'done': set.done ? 1 : 0,
          'type': set.type.name,
        });
      }
    }

    return workoutId;
  }

  Future<List<Workout>> getWorkouts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('workouts', orderBy: 'date DESC');
    
    List<Workout> workouts = [];
    for (var workoutMap in maps) {
      final exercises = await _getExercisesForWorkout(workoutMap['id']);
      workouts.add(Workout(
        date: workoutMap['date'],
        exercises: exercises,
      ));
    }
    
    return workouts;
  }

  Future<List<Exercise>> _getExercisesForWorkout(int workoutId) async {
    final db = await database;
    final List<Map<String, dynamic>> exerciseMaps = await db.query(
      'exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );

    List<Exercise> exercises = [];
    for (var exerciseMap in exerciseMaps) {
      final sets = await _getSetsForExercise(exerciseMap['id']);
      exercises.add(Exercise(
        id: exerciseMap['id'],
        name: exerciseMap['name'],
        notes: exerciseMap['notes'] ?? '',
        sets: sets,
        supersetWith: exerciseMap['superset_with'],
      ));
    }

    return exercises;
  }

  Future<List<ExerciseSet>> _getSetsForExercise(String exerciseId) async {
    final db = await database;
    final List<Map<String, dynamic>> setMaps = await db.query(
      'exercise_sets',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
    );

    return setMaps.map((setMap) => ExerciseSet(
      weight: setMap['weight'],
      reps: setMap['reps'],
      done: setMap['done'] == 1,
      type: SetType.values.firstWhere(
        (e) => e.name == setMap['type'],
        orElse: () => SetType.normal,
      ),
    )).toList();
  }

  Future<void> deleteWorkout(int date) async {
    final db = await database;
    final workout = await db.query(
      'workouts',
      where: 'date = ?',
      whereArgs: [date],
    );
    
    if (workout.isNotEmpty) {
      await db.delete('workouts', where: 'id = ?', whereArgs: [workout.first['id']]);
    }
  }

  // CRUD operace pro knihovnu cviků
  Future<void> insertLibraryExercise(LibraryExercise exercise) async {
    final db = await database;
    await db.insert('library_exercises', {
      'id': exercise.id,
      'name': exercise.name,
      'group_name': exercise.group,
      'default_rest_time': exercise.defaultRestTime,
    });
  }

  Future<List<LibraryExercise>> getLibraryExercises() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('library_exercises');
    
    return maps.map((map) => LibraryExercise(
      id: map['id'],
      name: map['name'],
      group: map['group_name'],
      defaultRestTime: map['default_rest_time'],
    )).toList();
  }

  // CRUD operace pro šablony
  Future<void> insertWorkoutTemplate(WorkoutTemplate template) async {
    final db = await database;
    await db.insert('workout_templates', {
      'id': template.id,
      'name': template.name,
    });

    for (var exercise in template.exercises) {
      await db.insert('template_exercises', {
        'template_id': template.id,
        'exercise_id': exercise.id,
      });
    }

    for (var day in template.scheduleDays) {
      await db.insert('schedule_days', {
        'template_id': template.id,
        'day': day,
      });
    }
  }

  Future<List<WorkoutTemplate>> getWorkoutTemplates() async {
    final db = await database;
    final List<Map<String, dynamic>> templateMaps = await db.query('workout_templates');
    
    List<WorkoutTemplate> templates = [];
    for (var templateMap in templateMaps) {
      final exercises = await _getTemplateExercises(templateMap['id']);
      final scheduleDays = await _getTemplateScheduleDays(templateMap['id']);
      
      templates.add(WorkoutTemplate(
        id: templateMap['id'],
        name: templateMap['name'],
        exercises: exercises,
        scheduleDays: scheduleDays,
      ));
    }
    
    return templates;
  }

  Future<List<Exercise>> _getTemplateExercises(String templateId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT e.* FROM library_exercises e
      INNER JOIN template_exercises te ON e.id = te.exercise_id
      WHERE te.template_id = ?
    ''', [templateId]);

    return maps.map((map) => Exercise(
      id: map['id'],
      name: map['name'],
      sets: [ExerciseSet(weight: 50, reps: 8)],
    )).toList();
  }

  Future<List<int>> _getTemplateScheduleDays(String templateId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedule_days',
      where: 'template_id = ?',
      whereArgs: [templateId],
    );
    
    return maps.map((map) => map['day'] as int).toList();
  }

  // CRUD operace pro váhu
  Future<void> insertWeightEntry(WeightEntry entry) async {
    final db = await database;
    await db.insert('weight_entries', {
      'date': entry.date.millisecondsSinceEpoch,
      'weight': entry.weight,
    });
  }

  Future<List<WeightEntry>> getWeightEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'weight_entries',
      orderBy: 'date DESC',
    );
    
    return maps.map((map) => WeightEntry(
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      weight: map['weight'],
    )).toList();
  }

  // CRUD operace pro profil
  Future<void> saveProfile(Profile profile, {String? name}) async {
    final db = await database;
    await db.insert('profile', {
      'age': profile.age,
      'height': profile.height,
      'gender': profile.gender,
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Profile?> getProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('profile', limit: 1);
    
    if (maps.isEmpty) return null;
    
    return Profile(
      age: maps.first['age'] ?? '',
      height: maps.first['height'] ?? '',
      gender: maps.first['gender'] ?? 'Jiné',
    );
  }

  Future<String?> getUserName() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('profile', limit: 1);
    return maps.isNotEmpty ? maps.first['name'] : null;
  }
} 