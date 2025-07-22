import 'models.dart';
import 'dart:math';

class CoachTip {
  final String id;
  final String text;
  CoachTip(this.id, this.text);
}

class CoachService {
  final Profile profile;
  final List<Workout> workouts;
  final DateTime? lastWorkoutDate;
  final List<WeightEntry> weightHistory;

  CoachService({required this.profile, required this.workouts, this.lastWorkoutDate, this.weightHistory = const []});

  /// Vrací seznam tipů, které nejsou ve skrytých (hiddenTipIds)
  List<CoachTip> getTips({List<String> hiddenTipIds = const []}) {
    List<CoachTip> tips = [];
    final goal = profile.goal;
    final now = DateTime.now();

    // 1. Před tréninkem
    if (_isBeforeWorkout()) {
      tips.add(CoachTip('warmup', "Nezapomeň na rozcvičení! Dej si 5 minut lehkého kardio a dynamický strečink."));
    }

    // 2. Po tréninku
    if (_isAfterWorkout()) {
      tips.add(CoachTip('stretch', "Skvělá práce! Nezapomeň na protažení a doplnění tekutin."));
    }

    // 3. Dlouhé pauzy (pokud bys měřil čas mezi sériemi, zde by byla logika)
    // tips.add(CoachTip('long_rest', "Dáváš si mezi sériemi moc dlouhé pauzy. Zkus je zkrátit na 90 sekund pro lepší efekt."));

    // 4. Nerovnoměrné zatížení svalových skupin
    final neglected = _neglectedMuscleGroup();
    if (neglected != null) {
      tips.add(CoachTip('neglected_$neglected', "Už delší dobu jsi necvičil $neglected. Nezapomeň na vyváženost!"));
    }

    // 5. Rychlý progres
    if (_isProgressTooFast()) {
      tips.add(CoachTip('fast_progress', "Přidáváš váhu moc rychle. Dej si pozor na techniku a zranění."));
    }

    // 6. Stagnace
    if (_isStagnating()) {
      tips.add(CoachTip('stagnation', "Všiml jsem si stagnace. Zvaž deload nebo změnu tréninku!"));
    }

    // 7. Pokles výkonu
    if (_isPerformanceDropping()) {
      tips.add(CoachTip('performance_drop', "Dnes jsi zvládl méně opakování než obvykle. Možná jsi unavený – zvaž deload nebo více spánku."));
    }

    // 8. Motivace po těžkém tréninku
    if (_lastRPE() >= 9) {
      tips.add(CoachTip('hard_training', "Tohle byl náročný trénink! Každý den nemusí být rekordní, důležitá je konzistence."));
    }

    // 9. Vynechání tréninku
    if (_daysSinceLastWorkout() > 5) {
      tips.add(CoachTip('missed_training', "Dlouho jsi necvičil. Vrať se do toho, i krátký trénink se počítá!"));
    }

    // 10. Personalizované rady podle cíle
    if (goal == "Síla") {
      tips.add(CoachTip('strength_technique', "Pro sílu je klíčová technika. Zkus si natočit video a zkontrolovat provedení."));
      tips.add(CoachTip('strength_rest', "Dbej na dostatečně dlouhé pauzy mezi sériemi (2–4 minuty) pro maximální sílu."));
    } else if (goal == "Objem") {
      tips.add(CoachTip('hypertrophy_negative', "Chceš nabrat svaly? Zaměř se na pomalé negativní fáze pohybu."));
      tips.add(CoachTip('hypertrophy_pump', "Pro maximální růst zařaď občas dropsety nebo supersérie."));
    } else if (goal == "Vytrvalost") {
      tips.add(CoachTip('endurance_circuit', "Zkus zařadit supersérie nebo kruhový trénink pro vyšší tepovku."));
      tips.add(CoachTip('endurance_short_rest', "Kratší pauzy (30–60 s) ti pomohou zlepšit vytrvalost."));
    } else if (goal == "Hubnutí") {
      tips.add(CoachTip('fatloss_cardio', "Kombinuj silový trénink s kardiem a sleduj kalorický příjem."));
      tips.add(CoachTip('fatloss_steps', "Zkus zvýšit denní počet kroků – i chůze pomáhá hubnutí!"));
    }

    // 11. Týdenní shrnutí
    if (_isWeeklySummaryDay()) {
      tips.add(CoachTip('weekly_summary', _weeklySummary()));
    }

    // 12. Kontextové tipy na techniku při stagnaci
    if (_isStagnating()) {
      tips.add(CoachTip('stagnation_technique', "U některých cviků může pomoci změna úchopu nebo tempa. Zkus experimentovat!"));
    }

    // 13. Upozornění na monotónnost
    if (_isMonotonous()) {
      tips.add(CoachTip('monotony', "Už několik tréninků za sebou máš stejný plán. Zkus změnit pořadí cviků nebo přidat nový prvek."));
    }

    // 14. Motivační tipy (náhodně)
    final motivational = [
      CoachTip('motivation_consistency', "Důležitá je pravidelnost, ne dokonalost!"),
      CoachTip('motivation_small_steps', "I malý pokrok je pokrok. Každý trénink se počítá!"),
      CoachTip('motivation_enjoy', "Užívej si cestu, nejen cíl."),
      CoachTip('motivation_rest', "Regenerace je stejně důležitá jako trénink."),
      CoachTip('motivation_celebrate', "Oslav každý úspěch, i ten malý!"),
    ];
    tips.add(motivational[Random().nextInt(motivational.length)]);

    // 15. Tipy na regeneraci
    tips.add(CoachTip('recovery_sleep', "Dostatek spánku je základ pro růst i regeneraci."));
    tips.add(CoachTip('recovery_nutrition', "Nezapomeň na kvalitní stravu po tréninku – bílkoviny a sacharidy pomáhají regeneraci."));

    // 16. Tipy na techniku
    tips.add(CoachTip('technique_breath', "Správné dýchání ti pomůže zvládnout těžké série. Nadechni se před opakováním a vydechuj při zvedání."));
    tips.add(CoachTip('technique_control', "Cvič kontrolovaně, neházej s činkou. Pomalejší pohyb = lepší technika a menší riziko zranění."));

    // Filtrování skrytých tipů
    final filtered = tips.where((tip) => !hiddenTipIds.contains(tip.id)).toList();
    filtered.shuffle();
    return filtered.take(1).toList(); // Zobraz max 1 tip najednou
  }

  // --- Pomocné metody ---
  bool _isBeforeWorkout() {
    // Můžeš implementovat podle stavu aplikace
    return false;
  }

  bool _isAfterWorkout() {
    // Můžeš implementovat podle stavu aplikace
    return false;
  }

  String? _neglectedMuscleGroup() {
    // Pokud máš skupiny cviků, můžeš analyzovat, která skupina nebyla dlouho cvičena
    return null;
  }

  bool _isProgressTooFast() {
    // Pokud uživatel přidává >10 % váhy týdně na hlavním cviku
    return false;
  }

  bool _isStagnating() {
    // Pokud 3x zopakuje stejný výkon na hlavním cviku
    if (workouts.length < 3) return false;
    final w1 = workouts[0];
    final w2 = workouts[1];
    final w3 = workouts[2];
    if (w1.exercises.isEmpty || w2.exercises.isEmpty || w3.exercises.isEmpty) return false;
    final n1 = w1.exercises[0].sets[0].weight;
    final n2 = w2.exercises[0].sets[0].weight;
    final n3 = w3.exercises[0].sets[0].weight;
    return n1 == n2 && n2 == n3;
  }

  bool _isPerformanceDropping() {
    // Pokud výkon klesá 2x po sobě a všechny tři tréninky jsou v posledních 14 dnech
    if (workouts.length < 3) return false;
    final w1 = workouts[0];
    final w2 = workouts[1];
    final w3 = workouts[2];
    if (w1.exercises.isEmpty || w2.exercises.isEmpty || w3.exercises.isEmpty) return false;
    final now = DateTime.now();
    final d1 = DateTime.fromMillisecondsSinceEpoch(w1.date);
    final d2 = DateTime.fromMillisecondsSinceEpoch(w2.date);
    final d3 = DateTime.fromMillisecondsSinceEpoch(w3.date);
    // Kontrola, že všechny tři tréninky jsou v posledních 14 dnech
    if (now.difference(d1).inDays > 14 || now.difference(d2).inDays > 14 || now.difference(d3).inDays > 14) {
      return false;
    }
    final n1 = w1.exercises[0].sets[0].weight;
    final n2 = w2.exercises[0].sets[0].weight;
    final n3 = w3.exercises[0].sets[0].weight;
    return n1 < n2 && n2 < n3;
  }

  int _lastRPE() {
    // Pokud ukládáš RPE, můžeš zde analyzovat poslední hodnotu
    return 0;
  }

  int _daysSinceLastWorkout() {
    if (workouts.isEmpty) return 999;
    final last = DateTime.fromMillisecondsSinceEpoch(workouts.first.date);
    return DateTime.now().difference(last).inDays;
  }

  bool _isWeeklySummaryDay() {
    // Například každou neděli
    return DateTime.now().weekday == DateTime.sunday;
  }

  String _weeklySummary() {
    final weekWorkouts = workouts.where((w) => DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(w.date)).inDays < 7).length;
    return "Tento týden jsi odcvičil $weekWorkouts tréninků. Jen tak dál!";
  }

  bool _isMonotonous() {
    // Pokud uživatel 5x za sebou cvičí stejný plán
    if (workouts.length < 5) return false;
    final names = workouts.take(5).map((w) => w.exercises.map((e) => e.name).join(",")).toSet();
    return names.length == 1;
  }
} 