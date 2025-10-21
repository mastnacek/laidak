import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pomodoro_provider.dart';




/// Panel s nastavenim Pomodoro (work duration, break duration, atd.)
class SettingsPanel extends ConsumerWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoroAsync = ref.watch(pomodoroProvider);

    return pomodoroAsync.when(
      data: (state) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nastaveni',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Work Duration
                ListTile(
                  leading: const Icon(Icons.work, color: Colors.blue),
                  title: const Text('Delka prace'),
                  trailing: Text(
                    '${state.config.workDuration.inMinutes} min',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),

                // Break Duration
                ListTile(
                  leading: const Icon(Icons.coffee, color: Colors.green),
                  title: const Text('Delka pauzy'),
                  trailing: Text(
                    '${state.config.breakDuration.inMinutes} min',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),

                // Auto-start break
                SwitchListTile(
                  secondary: const Icon(Icons.auto_awesome, color: Colors.orange),
                  title: const Text('Auto-start prestavky'),
                  subtitle: const Text('Automaticky spustit prestavku po dokonceni'),
                  value: state.config.autoStartBreak,
                  onChanged: (value) {
                    final newConfig = state.config.copyWith(autoStartBreak: value);
                    ref.read(pomodoroProvider.notifier).add(UpdateConfigEvent(newConfig));
                  },
                ),
                const Divider(),

                // Sound
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up, color: Colors.purple),
                  title: const Text('Zvuk pri dokonceni'),
                  subtitle: const Text('Prehrat zvukovy signal'),
                  value: state.config.soundEnabled,
                  onChanged: (value) {
                    final newConfig = state.config.copyWith(soundEnabled: value);
                    ref.read(pomodoroProvider.notifier).add(UpdateConfigEvent(newConfig));
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
