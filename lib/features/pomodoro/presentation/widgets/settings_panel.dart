import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/pomodoro_bloc.dart';
import '../bloc/pomodoro_event.dart';
import '../bloc/pomodoro_state.dart';

/// Panel s nastaven�m Pomodoro (work duration, break duration, atd.)
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroBloc, PomodoroState>(
      buildWhen: (previous, current) => previous.config != current.config,
      builder: (context, state) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '� Nastaven�',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Work Duration
                ListTile(
                  leading: const Icon(Icons.work, color: Colors.blue),
                  title: const Text('D�lka pr�ce'),
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
                  title: const Text('D�lka pauzy'),
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
                  title: const Text('Auto-start pYest�vky'),
                  subtitle: const Text('Automaticky spustit pYest�vku po dokonen�'),
                  value: state.config.autoStartBreak,
                  onChanged: (value) {
                    final newConfig = state.config.copyWith(autoStartBreak: value);
                    context.read<PomodoroBloc>().add(UpdateConfigEvent(newConfig));
                  },
                ),
                const Divider(),

                // Sound
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up, color: Colors.purple),
                  title: const Text('Zvuk pYi dokonen�'),
                  subtitle: const Text('PYehr�t zvukov� sign�l'),
                  value: state.config.soundEnabled,
                  onChanged: (value) {
                    final newConfig = state.config.copyWith(soundEnabled: value);
                    context.read<PomodoroBloc>().add(UpdateConfigEvent(newConfig));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
