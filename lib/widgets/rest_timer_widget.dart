import 'dart:math';
import 'package:flutter/material.dart';

class RestTimerWidget extends StatelessWidget {
  final int currentRestSeconds;
  final int totalRestSeconds;
  final VoidCallback onTimerTap;
  final VoidCallback onCancelTimer;

  const RestTimerWidget({
    super.key,
    required this.currentRestSeconds,
    required this.totalRestSeconds,
    required this.onTimerTap,
    required this.onCancelTimer,
  });

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (currentRestSeconds / totalRestSeconds);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTimerTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: -5,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(  
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Odpočinek:', style: TextStyle(fontSize: 18)),
                  ],
                ),
                Text(
                  '${(currentRestSeconds ~/ 60).toString().padLeft(2, '0')}:${(currentRestSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.bold, 
                    color: theme.primaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onCancelTimer,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade800,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Klepnutím změnit čas',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CircularRestTimerWidget extends StatelessWidget {
  final int currentRestSeconds;
  final int totalRestSeconds;
  final VoidCallback onTimerTap;
  final VoidCallback onCancelTimer;

  const CircularRestTimerWidget({
    super.key,
    required this.currentRestSeconds,
    required this.totalRestSeconds,
    required this.onTimerTap,
    required this.onCancelTimer,
  });

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (currentRestSeconds / totalRestSeconds);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTimerTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: -5,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Odpočinek:', style: TextStyle(fontSize: 18)),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                    strokeWidth: 8,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(currentRestSeconds ~/ 60).toString().padLeft(2, '0')}:${(currentRestSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: theme.primaryColor,
                      ),
                    ),
                    Text(
                      'sekund',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onCancelTimer,
            ),
          ],
        ),
      ),
    );
  }
}
