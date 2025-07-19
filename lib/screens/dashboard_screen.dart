import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/glassmorphic_card.dart';
import '../theme.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final String title = 'Přehled';
  final Map<int, String> schedule;
  final List<WorkoutTemplate> templates;
  final List<Workout> pastWorkouts;
  final Function(DateTime date, {List<Exercise>? templateExercises}) onStartWorkout;

  const DashboardScreen({
    super.key,
    required this.schedule,
    required this.templates,
    required this.pastWorkouts,
    required this.onStartWorkout,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoaded = false;
  String _userName = 'uživateli';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadName();
    // Spustit animace po načtení UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isLoaded = true;
      });
      _animationController.forward();
    });
  }

  void _loadName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName')?.isNotEmpty == true ? prefs.getString('userName')! : 'uživateli';
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = _userName;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Animovaný header
          SliverToBoxAdapter(
            child: AnimatedOpacity(
              opacity: _isLoaded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedPadding(
                padding: EdgeInsets.only(
                  left: 20, 
                  right: 20, 
                  top: _isLoaded ? 20 : 40, 
                  bottom: 10
                ),
                duration: const Duration(milliseconds: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ahoj, $userName!',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getMotivationalQuote(),
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Animované karty
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),

              // Dnešní trénink
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return AnimatedOpacity(
                    opacity: _isLoaded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: AnimatedPadding(
                      padding: EdgeInsets.only(
                        left: 16, 
                        right: 16, 
                        top: _isLoaded ? 0 : 30,
                      ),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      child: _buildTodayWorkoutCard(context),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Týdenní přehled
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return AnimatedOpacity(
                    opacity: _isLoaded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: AnimatedPadding(
                      padding: EdgeInsets.only(
                        left: 16, 
                        right: 16, 
                        top: _isLoaded ? 0 : 30,
                      ),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      child: _buildWeeklyOverview(context),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Statistiky
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return AnimatedOpacity(
                    opacity: _isLoaded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: AnimatedPadding(
                      padding: EdgeInsets.only(
                        left: 16, 
                        right: 16, 
                        top: _isLoaded ? 0 : 30,
                        bottom: 30,
                      ),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOutCubic,
                      child: _buildQuickStats(context),
                    ),
                  );
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }

  String _getMotivationalQuote() {
    final quotes = [
      'Každý trénink tě přibližuje k tvým cílům.',
      'Síla není dána fyzickými schopnostmi, ale neporazitelnou vůlí.',
      'Dnes investuj do svého budoucího já.',
      'Nestačí jen chtít, musíš pro to něco udělat.',
      'Nezáleží na tom, jak pomalu jdeš, hlavně když nezastavíš.',
      'Nejlepší projekt, na kterém můžeš pracovat, jsi ty sám.',
      'Bolest je dočasná, hrdost je věčná.',
    ];

    return quotes[math.Random().nextInt(quotes.length)];
  }

  Widget _buildTodayWorkoutCard(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final dayOfWeek = today.weekday;
    final scheduledTemplateId = widget.schedule[dayOfWeek];
    WorkoutTemplate? scheduledTemplate;

    if (scheduledTemplateId != null) {
      try {
        scheduledTemplate = widget.templates.firstWhere((t) => t.id == scheduledTemplateId);
      } catch (e) {
        scheduledTemplate = null;
      }
    }

    return GlassmorphicCard(
      borderRadius: 24,
      blur: 15,
      opacity: 0.1,
      borderWidth: 1.5,
      borderColor: Colors.white,
      child: Column(
        children: [
          // Header s ikonou
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: theme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Dnešní trénink', 
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Obsah karty
          if (scheduledTemplate != null) ...[  
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_note, 
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scheduledTemplate.name,
                          style: TextStyle(
                            fontSize: 18, 
                            color: theme.primaryColor, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${scheduledTemplate.exercises.length} cviků',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[  // Opraveno ze [] na ...[] aby vrátilo správné typy
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, color: Colors.white54),
                  SizedBox(width: 10),
                  Text(
                    'Dnes nemáš nic naplánováno',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Tlačítko pro zahájení tréninku
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: Text(
              scheduledTemplate != null ? 'Začít naplánovaný trénink' : 'Začít nový trénink',
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              widget.onStartWorkout(DateTime.now(), templateExercises: scheduledTemplate?.exercises);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
    final todayWeekday = DateTime.now().weekday;

    return GlassmorphicCard(
      borderRadius: 24,
      blur: 15,
      opacity: 0.1,
      borderWidth: 1.5,
      borderColor: Colors.white,
      child: Column(
        children: [
          // Header s ikonou
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_view_week,
                  color: AppTheme.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Týdenní plán', 
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Dny v týdnu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final dayIndex = index + 1;
              final isScheduled = widget.schedule.containsKey(dayIndex);
              final isToday = dayIndex == todayWeekday;

              String? planName;
              if (isScheduled) {
                final templateId = widget.schedule[dayIndex];
                final template = widget.templates.firstWhere(
                  (t) => t.id == templateId,
                  orElse: () => WorkoutTemplate(id: '', name: '', exercises: []),
                );
                planName = template.name;
              }

              return Column(
                children: [
                  // Den
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isToday ? theme.primaryColor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isToday ? theme.primaryColor : Colors.white30,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        days[index],
                        style: TextStyle(
                          color: isToday ? Colors.white : Colors.white70,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Indikátor tréninku
                  Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: isScheduled ? AppTheme.accentColor : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Název plánu (pokud existuje)
                  if (planName != null && planName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        planName,
                        style: TextStyle(
                          fontSize: 10,
                          color: isToday ? theme.primaryColor : AppTheme.accentColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final workoutsThisMonth = widget.pastWorkouts.where(
      (w) => DateTime.fromMillisecondsSinceEpoch(w.date).month == now.month && 
            DateTime.fromMillisecondsSinceEpoch(w.date).year == now.year
    ).length;

    final totalWorkouts = widget.pastWorkouts.length;
    final workoutsLastMonth = widget.pastWorkouts.where(
      (w) => DateTime.fromMillisecondsSinceEpoch(w.date).month == (now.month == 1 ? 12 : now.month - 1) &&
            DateTime.fromMillisecondsSinceEpoch(w.date).year == (now.month == 1 ? now.year - 1 : now.year)
    ).length;

    final monthProgress = (workoutsThisMonth / (workoutsLastMonth > 0 ? workoutsLastMonth : 1));
    final trend = monthProgress > 1 ? 'Lepší než minulý měsíc!' : 'Pokračuj v tréninku!'; 

    return GlassmorphicCard(
      borderRadius: 24,
      blur: 15,
      opacity: 0.1,
      borderWidth: 1.5,
      borderColor: Colors.white,
      child: Column(
        children: [
          // Header s ikonou
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insert_chart,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tvoje statistiky', 
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Statistiky
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Tréninky tento měsíc
              _buildStatCard(
                context: context,
                value: workoutsThisMonth.toString(),
                label: 'Tréninky tento měsíc',
                icon: Icons.calendar_month,
                color: theme.primaryColor,
              ),

              // Celkem tréninků
              _buildStatCard(
                context: context,
                value: totalWorkouts.toString(),
                label: 'Celkem tréninků',
                icon: Icons.fitness_center,
                color: AppTheme.accentColor,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Trend
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: (monthProgress > 1 ? Colors.green : Colors.amber).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  monthProgress > 1 ? Icons.trending_up : Icons.trending_flat,
                  color: monthProgress > 1 ? Colors.green : Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: monthProgress > 1 ? Colors.green : Colors.amber,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
