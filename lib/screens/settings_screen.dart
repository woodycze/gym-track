import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/glassmorphic_card.dart';
import '../notification_service.dart';
import '../database_helper.dart';
import '../models.dart';

class SettingsScreen extends StatefulWidget {
  final Profile profile;
  final Function(Profile) onProfileUpdate;
  final Function() onDataExport;
  final Function() onDataImport;

  const SettingsScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdate,
    required this.onDataExport,
    required this.onDataImport,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  String _selectedGender = 'Jiné';
  bool _notificationsEnabled = true;
  TimeOfDay _workoutReminderTime = const TimeOfDay(hour: 18, minute: 0);
  List<int> _workoutDays = [1, 3, 5]; // Po, St, Pá
  bool _deloadReminders = true;
  bool _restDayReminders = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '');
    _ageController = TextEditingController(text: widget.profile.age);
    _heightController = TextEditingController(text: widget.profile.height);
    _selectedGender = widget.profile.gender;
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    // Načtení nastavení z SharedPreferences
    // Toto je zjednodušená verze - v reálné aplikaci byste načítali z databáze
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Nastavení'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            const SizedBox(height: 24),
            _buildNotificationSection(),
            const SizedBox(height: 24),
            _buildDataSection(),
            const SizedBox(height: 24),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profil',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Jméno
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Jméno',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Věk
            TextField(
              controller: _ageController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Věk',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Výška
            TextField(
              controller: _heightController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Výška (cm)',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Pohlaví
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Pohlaví',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
              ),
              dropdownColor: AppTheme.cardColor,
              style: const TextStyle(color: Colors.white),
              items: ['Muž', 'Žena', 'Jiné'].map((gender) {
                return DropdownMenuItem(value: gender, child: Text(gender));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Uložit profil'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifikace',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Přepínač notifikací
            SwitchListTile(
              title: const Text('Povolit notifikace', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Zobrazovat připomínky na tréninky', style: TextStyle(color: Colors.white70)),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeColor: Colors.blue,
            ),
            
            if (_notificationsEnabled) ...[
              const SizedBox(height: 16),
              
              // Čas připomínky
              ListTile(
                title: const Text('Čas připomínky', style: TextStyle(color: Colors.white)),
                subtitle: Text(_workoutReminderTime.format(context), style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.access_time, color: Colors.white70),
                onTap: _selectTime,
              ),
              
              const SizedBox(height: 16),
              
              // Dny tréninků
              const Text('Dny tréninků:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildDayChip('Po', 1),
                  _buildDayChip('Út', 2),
                  _buildDayChip('St', 3),
                  _buildDayChip('Čt', 4),
                  _buildDayChip('Pá', 5),
                  _buildDayChip('So', 6),
                  _buildDayChip('Ne', 7),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Deload připomínky
              SwitchListTile(
                title: const Text('Deload připomínky', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Upozornění na deload týden', style: TextStyle(color: Colors.white70)),
                value: _deloadReminders,
                onChanged: (value) {
                  setState(() {
                    _deloadReminders = value;
                  });
                },
                activeColor: Colors.blue,
              ),
              
              // Dny odpočinku
              SwitchListTile(
                title: const Text('Dny odpočinku', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Připomínky na regeneraci', style: TextStyle(color: Colors.white70)),
                value: _restDayReminders,
                onChanged: (value) {
                  setState(() {
                    _restDayReminders = value;
                  });
                },
                activeColor: Colors.blue,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.download, color: Colors.white70),
              title: const Text('Exportovat data', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Uložit zálohu tréninků', style: TextStyle(color: Colors.white70)),
              onTap: widget.onDataExport,
            ),
            
            ListTile(
              leading: const Icon(Icons.upload, color: Colors.white70),
              title: const Text('Importovat data', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Načíst zálohu tréninků', style: TextStyle(color: Colors.white70)),
              onTap: widget.onDataImport,
            ),
            
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Smazat všechna data', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Nevratné smazání všech dat', style: TextStyle(color: Colors.white70)),
              onTap: _showDeleteConfirmation,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O aplikaci',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white70),
              title: const Text('Verze', style: TextStyle(color: Colors.white)),
              subtitle: const Text('1.0.0', style: TextStyle(color: Colors.white70)),
            ),
            
            ListTile(
              leading: const Icon(Icons.description, color: Colors.white70),
              title: const Text('Licence', style: TextStyle(color: Colors.white)),
              subtitle: const Text('MIT License', style: TextStyle(color: Colors.white70)),
              onTap: _showLicense,
            ),
            
            ListTile(
              leading: const Icon(Icons.feedback, color: Colors.white70),
              title: const Text('Zpětná vazba', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Nahlásit problém nebo návrh', style: TextStyle(color: Colors.white70)),
              onTap: _showFeedback,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(String label, int day) {
    final isSelected = _workoutDays.contains(day);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _workoutDays.add(day);
          } else {
            _workoutDays.remove(day);
          }
        });
      },
      selectedColor: Colors.blue,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _workoutReminderTime,
    );
    if (picked != null) {
      setState(() {
        _workoutReminderTime = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    final updatedProfile = Profile(
      age: _ageController.text,
      height: _heightController.text,
      gender: _selectedGender,
    );
    
    widget.onProfileUpdate(updatedProfile);
    
    // Uložení do databáze
    final db = DatabaseHelper();
    await db.saveProfile(updatedProfile, name: _nameController.text);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil byl úspěšně uložen'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Smazat všechna data?'),
        content: const Text('Tato akce je nevratná. Všechna data budou trvale smazána.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zrušit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAllData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    // Implementace smazání všech dat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Všechna data byla smazána'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showLicense() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Licence'),
        content: const Text('MIT License\n\nCopyright (c) 2024 Gym Track\n\nPermission is hereby granted...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zavřít'),
          ),
        ],
      ),
    );
  }

  void _showFeedback() {
    // Implementace zpětné vazby
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funkce zpětné vazby bude brzy dostupná'),
      ),
    );
  }
} 