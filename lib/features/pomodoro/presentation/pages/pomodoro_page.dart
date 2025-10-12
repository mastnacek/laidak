import 'package:flutter/material.dart';

/// Pomodoro Timer Page
///
/// Hlavní stránka pro Pomodoro timer.
/// FÁZE 1: Základní scaffold (bez BLoC)
class PomodoroPage extends StatelessWidget {
  final int? taskId;
  final Duration? initialDuration;

  const PomodoroPage({
    super.key,
    this.taskId,
    this.initialDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍅 Pomodoro Timer'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder - zatím jenom basic UI
            const Icon(
              Icons.timer,
              size: 100,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            if (taskId != null)
              Text(
                'Úkol ID: $taskId',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
            if (initialDuration != null)
              Text(
                'Délka: ${initialDuration!.inMinutes} minut',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            const SizedBox(height: 32),
            const Text(
              '⏱️ Timer bude implementován v další fázi',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            const Text(
              '(MILESTONE 1: Core Timer Logic)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
