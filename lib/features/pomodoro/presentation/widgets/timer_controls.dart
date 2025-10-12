import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/pomodoro_bloc.dart';
import '../bloc/pomodoro_event.dart';
import '../bloc/pomodoro_state.dart';
import '../../domain/entities/timer_state.dart';

/// Widget s control buttons (Start/Pause/Resume/Stop/Break/Continue)
class TimerControls extends StatelessWidget {
  const TimerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroBloc, PomodoroState>(
      buildWhen: (previous, current) =>
          previous.timerState != current.timerState ||
          previous.currentTaskId != current.currentTaskId ||
          previous.sessionCount != current.sessionCount,
      builder: (context, state) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            // START button (pouze pokud idle)
            if (state.timerState == TimerState.idle)
              ElevatedButton.icon(
                onPressed: () => _showQuickStartDialog(context),
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text(
                  'START',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

            // PAUSE button (pouze pokud running)
            if (state.timerState == TimerState.running)
              ElevatedButton.icon(
                onPressed: () {
                  context.read<PomodoroBloc>().add(const PausePomodoroEvent());
                },
                icon: const Icon(Icons.pause, size: 28),
                label: const Text(
                  'PAUSE',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),

            // RESUME button (pouze pokud paused)
            if (state.timerState == TimerState.paused)
              ElevatedButton.icon(
                onPressed: () {
                  context.read<PomodoroBloc>().add(const ResumePomodoroEvent());
                },
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text(
                  'RESUME',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

            // STOP button (pokud bezi nebo paused)
            if (state.timerState != TimerState.idle)
              ElevatedButton.icon(
                onPressed: () {
                  _showStopConfirmDialog(context);
                },
                icon: const Icon(Icons.stop, size: 28),
                label: const Text(
                  'STOP',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),

            // BREAK button (pokud idle a ma session count)
            if (state.timerState == TimerState.idle && state.sessionCount > 0)
              ElevatedButton.icon(
                onPressed: () {
                  context.read<PomodoroBloc>().add(const StartBreakEvent());
                },
                icon: const Icon(Icons.coffee, size: 28),
                label: const Text(
                  'BREAK',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),

            // CONTINUE button (pokud idle a ma current task)
            if (state.timerState == TimerState.idle &&
                state.currentTaskId != null)
              ElevatedButton.icon(
                onPressed: () {
                  context.read<PomodoroBloc>().add(
                        const ContinuePomodoroEvent(),
                      );
                },
                icon: const Icon(Icons.refresh, size: 28),
                label: const Text(
                  'CONTINUE',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Dialog pro Quick Start (vyber task ID a delky)
  void _showQuickStartDialog(BuildContext context) {
    int taskId = 1; // Default task ID
    Duration customDuration = const Duration(minutes: 25); // Default duration

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Spustit Pomodoro'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Task ID input
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Task ID',
                    hintText: '1',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    taskId = int.tryParse(value) ?? 1;
                  },
                ),
                const SizedBox(height: 16),

                // Duration picker
                DropdownButtonFormField<int>(
                  value: customDuration.inMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Delka',
                    border: OutlineInputBorder(),
                  ),
                  items: [15, 25, 30, 45, 60].map((minutes) {
                    return DropdownMenuItem(
                      value: minutes,
                      child: Text('$minutes minut'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      customDuration = Duration(minutes: value ?? 25);
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Zrusit'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PomodoroBloc>().add(
                    StartPomodoroEvent(taskId, customDuration),
                  );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('START'),
          ),
        ],
      ),
    );
  }

  /// Potvrzovaci dialog pro Stop
  void _showStopConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Zastavit Pomodoro?'),
        content: const Text(
          'Opravdu chcete zastavit bezici Pomodoro? '
          'Session bude ulozena jako prerusena.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Ne'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PomodoroBloc>().add(const StopPomodoroEvent());
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ano, zastavit'),
          ),
        ],
      ),
    );
  }
}
