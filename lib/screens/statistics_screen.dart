import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/glassmorphic_card.dart';
import 'dart:math' as math;

class StatisticsScreen extends StatefulWidget {
  final String title = 'Statistiky';
  final List<Workout> workouts;
  final List<WeightEntry> weightHistory;

  const StatisticsScreen({
    super.key,
    required this.workouts,
    required this.weightHistory,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '30 dní';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        // title: const Text('Statistiky'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Přehled'),
            Tab(text: 'Výkonnost'),
            Tab(text: 'Váha'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPerformanceTab(),
          _buildWeightTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final filteredWorkouts = _getFilteredWorkouts();
    final stats = _calculateStats(filteredWorkouts);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          
          // Hlavní statistiky
          Row(
            children: [
              Expanded(child: _buildStatCard('Celkem tréninků', '${stats.totalWorkouts}', Icons.fitness_center)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Průměrně/týden', '${stats.avgWorkoutsPerWeek}', Icons.calendar_today)),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(child: _buildStatCard('Celkem cviků', '${stats.totalExercises}', Icons.sports_gymnastics)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Celkem sérií', '${stats.totalSets}', Icons.repeat)),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Nejpoužívanější cviky
          GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nejpoužívanější cviky',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._getMostUsedExercises(filteredWorkouts).take(5).map((exercise) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(exercise.name, style: const TextStyle(color: Colors.white70)),
                          Text('${exercise.count}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Graf frekvence tréninků
          GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frekvence tréninků',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildWorkoutFrequencyChart(filteredWorkouts),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    final filteredWorkouts = _getFilteredWorkouts();
    final performanceData = _getPerformanceData(filteredWorkouts);
    final volumeData = _getVolumeData(filteredWorkouts);
    final prediction = _getPrediction(performanceData);
    final splitRecommendation = _getSplitRecommendation(performanceData);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          // Graf progrese
          GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progrese v čase',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _buildProgressChart(performanceData),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Graf objemu
          GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Celkový objem (kg)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: _buildVolumeChart(volumeData),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Predikce a doporučení
          if (prediction != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(prediction, style: const TextStyle(color: Colors.blue))),
                ],
              ),
            ),
          if (splitRecommendation != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(splitRecommendation, style: const TextStyle(color: Colors.amber))),
                ],
              ),
            ),
          const SizedBox(height: 20),
          // Nejlepší výkony
          GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nejlepší výkony',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._getBestPerformances(filteredWorkouts).map((performance) {
                    // Najdi aktuální váhu (poslední záznam)
                    double? currentWeight = widget.weightHistory.isNotEmpty ? widget.weightHistory.first.weight : null;
                    String relStrength = '';
                    if (currentWeight != null && currentWeight > 0) {
                      final ratio = performance.weight / currentWeight;
                      relStrength = ' (${ratio.toStringAsFixed(2)}× tělesné hmotnosti)';
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(performance.exerciseName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('${performance.weight}kg × ${performance.reps} opakování$relStrength', style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                          Text(performance.date, style: const TextStyle(color: Colors.white60)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTab() {
    final filteredWeight = _getFilteredWeightHistory();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          
          // Graf váhy
          GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vývoj váhy',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: _buildWeightChart(filteredWeight),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Statistiky váhy
          if (filteredWeight.isNotEmpty) ...[
            Row(
              children: [
                Expanded(child: _buildStatCard('Počáteční', '${filteredWeight.last.weight}kg', Icons.trending_down)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Aktuální', '${filteredWeight.first.weight}kg', Icons.trending_up)),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(child: _buildStatCard('Změna', '${_calculateWeightChange(filteredWeight)}kg', Icons.balance)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Průměr', '${_calculateAverageWeight(filteredWeight)}kg', Icons.analytics)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: _selectedPeriod,
          decoration: const InputDecoration(
            labelText: 'Období',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
          ),
          dropdownColor: AppTheme.cardColor,
          style: const TextStyle(color: Colors.white),
          items: ['7 dní', '30 dní', '90 dní', '1 rok', 'Vše'].map((period) {
            return DropdownMenuItem(value: period, child: Text(period));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Workout> _getFilteredWorkouts() {
    final now = DateTime.now();
    int daysBack;
    
    switch (_selectedPeriod) {
      case '7 dní':
        daysBack = 7;
        break;
      case '30 dní':
        daysBack = 30;
        break;
      case '90 dní':
        daysBack = 90;
        break;
      case '1 rok':
        daysBack = 365;
        break;
      default:
        return widget.workouts;
    }
    
    final cutoffDate = now.subtract(Duration(days: daysBack));
    return widget.workouts.where((workout) {
      return DateTime.fromMillisecondsSinceEpoch(workout.date).isAfter(cutoffDate);
    }).toList();
  }

  List<WeightEntry> _getFilteredWeightHistory() {
    final now = DateTime.now();
    int daysBack;
    
    switch (_selectedPeriod) {
      case '7 dní':
        daysBack = 7;
        break;
      case '30 dní':
        daysBack = 30;
        break;
      case '90 dní':
        daysBack = 90;
        break;
      case '1 rok':
        daysBack = 365;
        break;
      default:
        return widget.weightHistory;
    }
    
    final cutoffDate = now.subtract(Duration(days: daysBack));
    return widget.weightHistory.where((entry) {
      return entry.date.isAfter(cutoffDate);
    }).toList();
  }

  WorkoutStats _calculateStats(List<Workout> workouts) {
    int totalExercises = 0;
    int totalSets = 0;
    
    for (var workout in workouts) {
      totalExercises += workout.exercises.length;
      for (var exercise in workout.exercises) {
        totalSets += exercise.sets.length;
      }
    }
    
    final weeks = _selectedPeriod == 'Vše' ? 52 : int.parse(_selectedPeriod.split(' ')[0]) / 7;
    final avgWorkoutsPerWeek = workouts.length / weeks;
    
    return WorkoutStats(
      totalWorkouts: workouts.length,
      totalExercises: totalExercises,
      totalSets: totalSets,
      avgWorkoutsPerWeek: avgWorkoutsPerWeek.toStringAsFixed(1),
    );
  }

  List<ExerciseUsage> _getMostUsedExercises(List<Workout> workouts) {
    Map<String, int> exerciseCount = {};
    
    for (var workout in workouts) {
      for (var exercise in workout.exercises) {
        exerciseCount[exercise.name] = (exerciseCount[exercise.name] ?? 0) + 1;
      }
    }
    
    return exerciseCount.entries.map((entry) => 
      ExerciseUsage(name: entry.key, count: entry.value)
    ).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  Widget _buildWorkoutFrequencyChart(List<Workout> workouts) {
    // Implementace grafu frekvence tréninků
    return Container(); // Placeholder
  }

  List<PerformanceData> _getPerformanceData(List<Workout> workouts) {
    // Implementace dat o výkonnosti
    return []; // Placeholder
  }

  Widget _buildProgressChart(List<PerformanceData> data) {
    if (data.isEmpty) {
      return const Center(child: Text('Žádná data', style: TextStyle(color: Colors.white70)));
    }
    // Skupiny podle cviku
    final exercises = data.map((d) => d.exerciseName).toSet().toList();
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red];
    List<LineChartBarData> lines = [];
    int colorIdx = 0;
    for (var exercise in exercises) {
      final exerciseData = data.where((d) => d.exerciseName == exercise).toList();
      if (exerciseData.length < 2) continue;
      // Body grafu
      final spots = exerciseData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.weight)).toList();
      // Trendová čára (lineární regrese)
      final n = spots.length;
      final xMean = spots.map((s) => s.x).reduce((a, b) => a + b) / n;
      final yMean = spots.map((s) => s.y).reduce((a, b) => a + b) / n;
      final numerator = spots.map((s) => (s.x - xMean) * (s.y - yMean)).reduce((a, b) => a + b);
      final denominator = spots.map((s) => (s.x - xMean) * (s.x - xMean)).reduce((a, b) => a + b);
      final slope = denominator == 0 ? 0 : numerator / denominator;
      final intercept = yMean - slope * xMean;
      final trendSpots = [
        FlSpot(0, intercept),
        FlSpot((n - 1).toDouble(), intercept + slope * (n - 1)),
      ];
      // Linie výkonu
      lines.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        color: colors[colorIdx % colors.length],
        barWidth: 3,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
      ));
      // Trendová čára
      lines.add(LineChartBarData(
        spots: trendSpots,
        isCurved: false,
        color: colors[colorIdx % colors.length].withOpacity(0.5),
        barWidth: 2,
        dashArray: [8, 4],
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      ));
      colorIdx++;
    }
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: lines,
      ),
    );
  }

  List<BestPerformance> _getBestPerformances(List<Workout> workouts) {
    Map<String, BestPerformance> bestPerformances = {};
    
    for (var workout in workouts) {
      final date = DateTime.fromMillisecondsSinceEpoch(workout.date);
      final dateStr = '${date.day}.${date.month}.${date.year}';
      
      for (var exercise in workout.exercises) {
        for (var set in exercise.sets) {
          final key = exercise.name;
          final current = BestPerformance(
            exerciseName: exercise.name,
            weight: set.weight,
            reps: set.reps,
            date: dateStr,
          );
          
          if (!bestPerformances.containsKey(key) || 
              set.weight > bestPerformances[key]!.weight ||
              (set.weight == bestPerformances[key]!.weight && set.reps > bestPerformances[key]!.reps)) {
            bestPerformances[key] = current;
          }
        }
      }
    }
    
    return bestPerformances.values.toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
  }

  Widget _buildWeightChart(List<WeightEntry> weightHistory) {
    if (weightHistory.isEmpty) {
      return const Center(
        child: Text(
          'Žádná data o váze',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    
    final sortedData = List<WeightEntry>.from(weightHistory)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: sortedData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.weight);
            }).toList(),
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  String _calculateWeightChange(List<WeightEntry> weightHistory) {
    if (weightHistory.length < 2) return '0.0';
    final change = weightHistory.first.weight - weightHistory.last.weight;
    return change.toStringAsFixed(1);
  }

  String _calculateAverageWeight(List<WeightEntry> weightHistory) {
    if (weightHistory.isEmpty) return '0.0';
    final sum = weightHistory.fold(0.0, (sum, entry) => sum + entry.weight);
    return (sum / weightHistory.length).toStringAsFixed(1);
  }

  // --- Nové: graf objemu ---
  List<VolumeData> _getVolumeData(List<Workout> workouts) {
    return workouts.map((w) {
      double total = 0;
      for (var ex in w.exercises) {
        for (var set in ex.sets) {
          total += set.weight * set.reps;
        }
      }
      return VolumeData(date: DateTime.fromMillisecondsSinceEpoch(w.date), volume: total);
    }).toList();
  }

  Widget _buildVolumeChart(List<VolumeData> data) {
    if (data.isEmpty) {
      return const Center(child: Text('Žádná data', style: TextStyle(color: Colors.white70)));
    }
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.volume)).toList();
    // Trendová čára
    final n = spots.length;
    final xMean = spots.map((s) => s.x).reduce((a, b) => a + b) / n;
    final yMean = spots.map((s) => s.y).reduce((a, b) => a + b) / n;
    final numerator = spots.map((s) => (s.x - xMean) * (s.y - yMean)).reduce((a, b) => a + b);
    final denominator = spots.map((s) => (s.x - xMean) * (s.x - xMean)).reduce((a, b) => a + b);
    final slope = denominator == 0 ? 0 : numerator / denominator;
    final intercept = yMean - slope * xMean;
    final trendSpots = [
      FlSpot(0, intercept),
      FlSpot((n - 1).toDouble(), intercept + slope * (n - 1)),
    ];
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.teal,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: trendSpots,
            isCurved: false,
            color: Colors.teal.withOpacity(0.5),
            barWidth: 2,
            dashArray: [8, 4],
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  // --- Nové: predikce ---
  String? _getPrediction(List<PerformanceData> data) {
    if (data.isEmpty) return null;
    // Vezmeme poslední trendovou čáru hlavního cviku
    final mainExercise = data.map((d) => d.exerciseName).toList().isNotEmpty ? data[0].exerciseName : null;
    final mainData = data.where((d) => d.exerciseName == mainExercise).toList();
    if (mainData.length < 2) return null;
    final spots = mainData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.weight)).toList();
    final n = spots.length;
    final xMean = spots.map((s) => s.x).reduce((a, b) => a + b) / n;
    final yMean = spots.map((s) => s.y).reduce((a, b) => a + b) / n;
    final numerator = spots.map((s) => (s.x - xMean) * (s.y - yMean)).reduce((a, b) => a + b);
    final denominator = spots.map((s) => (s.x - xMean) * (s.x - xMean)).reduce((a, b) => a + b);
    final slope = denominator == 0 ? 0 : numerator / denominator;
    final intercept = yMean - slope * xMean;
    final nextX = n + 4; // cca měsíc dopředu (4 týdny)
    final predicted = intercept + slope * nextX;
    if (slope.abs() < 0.01) return null; // pokud je trend plochý, nepredikujeme
    return 'Pokud budeš pokračovat tímto tempem, za měsíc zvládneš cca ${predicted.toStringAsFixed(1)} kg na cviku $mainExercise.';
  }

  // --- Nové: doporučení změny splitu/plánu ---
  String? _getSplitRecommendation(List<PerformanceData> data) {
    if (data.length < 3) return null;
    final mainExercise = data.map((d) => d.exerciseName).toList().isNotEmpty ? data[0].exerciseName : null;
    final mainData = data.where((d) => d.exerciseName == mainExercise).toList();
    if (mainData.length < 3) return null;
    final s1 = mainData[mainData.length - 1].weight;
    final s2 = mainData[mainData.length - 2].weight;
    final s3 = mainData[mainData.length - 3].weight;
    if ((s1 == s2 && s2 == s3) || (s1 < s2 && s2 <= s3)) {
      return 'Zdá se, že stagnuješ na cviku $mainExercise. Zvaž změnu splitu, přidej nový cvik nebo zařaď deload!';
    }
    return null;
  }
}

class WorkoutStats {
  final int totalWorkouts;
  final int totalExercises;
  final int totalSets;
  final String avgWorkoutsPerWeek;

  WorkoutStats({
    required this.totalWorkouts,
    required this.totalExercises,
    required this.totalSets,
    required this.avgWorkoutsPerWeek,
  });
}

class ExerciseUsage {
  final String name;
  final int count;

  ExerciseUsage({required this.name, required this.count});
}

class PerformanceData {
  final DateTime date;
  final double weight;
  final String exerciseName;

  PerformanceData({
    required this.date,
    required this.weight,
    required this.exerciseName,
  });
}

class BestPerformance {
  final String exerciseName;
  final double weight;
  final int reps;
  final String date;

  BestPerformance({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.date,
  });
} 

// --- datová třída pro objem ---
class VolumeData {
  final DateTime date;
  final double volume;
  VolumeData({required this.date, required this.volume});
} 