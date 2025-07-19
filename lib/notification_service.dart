// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;

// Mock notifikační služba - dočasně kvůli kompatibilitě

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Mock inicializace - dočasně kvůli kompatibilitě
    print('Notifikační služba inicializována (mock)');
  }

  Future<void> _requestPermissions() async {
    // Mock oprávnění - dočasně kvůli kompatibilitě
    print('Oprávnění pro notifikace udělena (mock)');
  }

  Future<void> scheduleWorkoutReminder({
    required int hour,
    required int minute,
    required List<int> days,
    required String message,
  }) async {
    // Mock naplánování notifikace - dočasně kvůli kompatibilitě
    print('Naplánována notifikace na $hour:$minute pro dny: $days - $message');
  }

  DateTime _nextInstanceOfTime(int hour, int minute, int dayOfWeek) {
    // Mock výpočet času - dočasně kvůli kompatibilitě
    final now = DateTime.now();
    return now.add(const Duration(hours: 1));
  }

    Future<void> showWorkoutCompletedNotification() async {
    // Mock notifikace - dočasně kvůli kompatibilitě
    print('Trénink dokončen! 💪 - Skvělá práce! Tvůj trénink byl úspěšně uložen.');
  }

  Future<void> showDeloadReminderNotification() async {
    // Mock notifikace - dočasně kvůli kompatibilitě
    print('Čas na deload! 🛠️ - Už jsi měl 8 tréninků v řadě. Zvaž deload týden pro regeneraci.');
  }

  Future<void> showRestDayReminderNotification() async {
    // Mock notifikace - dočasně kvůli kompatibilitě
    print('Den odpočinku 🌟 - Dnes je den odpočinku. Nezapomeň na regeneraci a správnou výživu!');
  }

  Future<void> cancelAllNotifications() async {
    // Mock zrušení notifikací - dočasně kvůli kompatibilitě
    print('Všechny notifikace zrušeny');
  }

  Future<void> cancelWorkoutReminders() async {
    // Mock zrušení notifikací - dočasně kvůli kompatibilitě
    print('Tréninkové připomínky zrušeny');
  }
} 