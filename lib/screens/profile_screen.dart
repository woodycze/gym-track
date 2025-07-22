import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models.dart';
import '../widgets/glassmorphic_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String title = 'Profil';
  final List<Workout> pastWorkouts;
  final Profile profile;
  final Function(Profile) onEditProfile;
  const ProfileScreen({super.key, required this.pastWorkouts, required this.profile, required this.onEditProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _nameController = TextEditingController();
  final List<WeightEntry> _weightHistory = [];
  String _selectedGender = 'Jiné';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  void _loadName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('userName') ?? '';
  }

  void _saveName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Jméno uloženo!')),
    );
  }

  void _addWeightEntry() {
    final double? weight = double.tryParse(_weightController.text);
    if (weight != null && weight > 0) {
      setState(() {
        _weightHistory.add(WeightEntry(date: DateTime.now(), weight: weight));
        _weightHistory.sort((a, b) => a.date.compareTo(b.date));
      });
      _weightController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final prs = _calculatePRs();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tvůj Profil', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 32),
          _buildStatsCard(context, stats),
          const SizedBox(height: 24),
          _buildPRsCard(context, prs),
          const SizedBox(height: 24),
          _buildWeightCard(context),
          const SizedBox(height: 24),
          _buildProfileCard(context),
        ],
      ),
    );
  }

  Map<String, String> _calculateStats() {
    int totalWorkouts = widget.pastWorkouts.length;
    int totalSets = 0;
    double totalVolume = 0;

    for (var workout in widget.pastWorkouts) {
      for (var exercise in workout.exercises) {
        totalSets += exercise.sets.length;
        for (var set in exercise.sets) {
          totalVolume += (set.weight * set.reps);
        }
      }
    }
    return {
      'totalWorkouts': totalWorkouts.toString(),
      'totalSets': totalSets.toString(),
      'totalVolume': totalVolume.toStringAsFixed(0),
    };
  }

  Map<String, String> _calculatePRs() {
    final prs = <String, double>{};
    const exercisesToTrack = ['Bench Press', 'Dřep', 'Mrtvý tah'];

    for (var exerciseName in exercisesToTrack) {
      double maxWeight = 0;
      for (var workout in widget.pastWorkouts) {
        for (var exercise in workout.exercises) {
          if (exercise.name == exerciseName) {
            for (var set in exercise.sets) {
              if (set.weight > maxWeight) {
                maxWeight = set.weight;
              }
            }
          }
        }
      }
      if (maxWeight > 0) {
        prs[exerciseName] = maxWeight;
      }
    }
    return prs.map((key, value) => MapEntry(key, '${value.toStringAsFixed(1)} kg'));
  }

  Widget _buildProfileCard(BuildContext context) {
    final theme = Theme.of(context);
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Základní údaje', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          _buildReadOnlyRow('Věk', widget.profile.age),
          const SizedBox(height: 12),
          _buildReadOnlyRow('Výška (cm)', widget.profile.height),
          const SizedBox(height: 12),
          _buildReadOnlyRow('Pohlaví', widget.profile.gender),
          const SizedBox(height: 12),
          _buildReadOnlyRow('Cíl', widget.profile.goal),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Upravit profil'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    profile: widget.profile,
                    onProfileUpdate: (profile) {
                      widget.onEditProfile(profile);
                      Navigator.of(context).pop();
                    },
                    onDataExport: () {},
                    onDataImport: () {},
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Row(
      children: [
        Text('$label:', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, Map<String, String> stats) {
    return GlassmorphicCard(
      child: Column(
        children: [
          Text('Celkové statistiky', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Tréninky', stats['totalWorkouts'] ?? '0', Colors.deepPurpleAccent),
              _buildStatItem('Série', stats['totalSets'] ?? '0', Colors.blueAccent),
              _buildStatItem('Objem (kg)', stats['totalVolume'] ?? '0', Colors.tealAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPRsCard(BuildContext context, Map<String, String> prs) {
    return GlassmorphicCard(
      child: Column(
        children: [
          Text('Osobní rekordy (1RM)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (prs.isEmpty)
            const Text('Zatím žádné rekordy.', style: TextStyle(color: Colors.white70))
          else
            Column(
              children: prs.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                    Text(entry.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              )).toList(),
            )
        ],
      ),
    );
  }

  Widget _buildWeightCard(BuildContext context) {
    return GlassmorphicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sledování váhy', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          TextField(controller: _weightController, decoration: const InputDecoration(labelText: 'Aktuální váha (kg)'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _addWeightEntry, child: const Text('Zaznamenat váhu')),
          const SizedBox(height: 24),
          Text('Vývoj váhy:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _weightHistory.isEmpty
                ? const Center(child: Text('Zatím žádná data pro graf.'))
                : LineChart(_buildChartData(context)),
          ),
          const SizedBox(height: 24),
          Text('Historie vážení:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildWeightHistoryList(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
      ],
    );
  }

  Widget _buildWeightHistoryList() {
    if (_weightHistory.isEmpty) {
      return const Center(child: Text('Žádné záznamy.'));
    }
    final recentHistory = _weightHistory.reversed.take(5).toList();
    return Column(
      children: recentHistory.map((entry) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(MaterialLocalizations.of(context).formatFullDate(entry.date), style: const TextStyle(color: Colors.white70)),
            Text('${entry.weight} kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      )).toList(),
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final spots = _weightHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.weight)).toList();
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: const LinearGradient(colors: [Colors.deepPurpleAccent, Colors.blueAccent]),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(colors: [Colors.deepPurpleAccent.withOpacity(0.3), Colors.blueAccent.withOpacity(0.3)]),
          ),
        ),
      ],
    );
  }
}
