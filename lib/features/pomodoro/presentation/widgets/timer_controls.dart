import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pomodoro_provider.dart';
import '../../domain/entities/timer_state.dart';

/// Widget s control buttons (Start/Pause/Resume/Stop/Break/Continue)
class TimerControls extends ConsumerWidget {
  const TimerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider).value;

    if (state == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
            // START button (pouze pokud idle)
            if (state.timerState == TimerState.idle)
              ElevatedButton.icon(
                onPressed: () => _showQuickStartDialog(context, ref),
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
                  ref.read(pomodoroProvider.notifier).add(const PausePomodoroEvent());
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
                  ref.read(pomodoroProvider.notifier).add(const ResumePomodoroEvent());
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
                  _showStopConfirmDialog(context, ref);
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
                  ref.read(pomodoroProvider.notifier).add(const StartBreakEvent());
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
                  _showContinueDialog(context, ref, state.currentTaskId!);
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

            // FINISH button (ukončit práci na úkolu)
            if (state.timerState == TimerState.idle &&
                state.currentTaskId != null)
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(pomodoroProvider.notifier).add(const FinishTaskEvent());
                },
                icon: const Icon(Icons.check_circle, size: 28),
                label: const Text(
                  'FINISH',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }

  /// Dialog pro Quick Start (vyber task ID a delky)
  void _showQuickStartDialog(BuildContext context, WidgetRef ref) {
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
              ref.read(pomodoroProvider.notifier).add(
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
  void _showStopConfirmDialog(BuildContext context, WidgetRef ref) {
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
              ref.read(pomodoroProvider.notifier).add(const StopPomodoroEvent());
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

  /// Dialog pro Continue (vyber delky pro dalsi session)
  void _showContinueDialog(BuildContext context, WidgetRef ref, int taskId) {
    int? selectedMinutes; // null = vlastní hodnota
    final customController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('🍅 Pokračovat v Pomodoro'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task info
              Text(
                'Úkol #$taskId',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Délka
              const Text(
                'Délka session:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Rychlé volby (tlačítka)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [1, 5, 15, 25, 30, 45, 60].map((minutes) {
                  final isSelected = selectedMinutes == minutes;
                  return OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedMinutes = minutes;
                        customController.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected
                          ? Colors.orange.withValues(alpha: 0.2)
                          : null,
                      side: BorderSide(
                        color: isSelected ? Colors.orange : Colors.grey,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      '$minutes min',
                      style: TextStyle(
                        color: isSelected ? Colors.orange : null,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Vlastní zadání (TextField)
              const Text(
                'Nebo zadej vlastní:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: customController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Zadej minuty (1-180)',
                  suffixText: 'min',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
                onChanged: (value) {
                  // Pokud user píše, zrušit vybranou rychlou volbu
                  if (value.isNotEmpty) {
                    setState(() {
                      selectedMinutes = null;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Zrušit'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Určit finální počet minut
                int? finalMinutes;
                if (selectedMinutes != null) {
                  finalMinutes = selectedMinutes;
                } else if (customController.text.isNotEmpty) {
                  finalMinutes = int.tryParse(customController.text);
                }

                // Validace
                if (finalMinutes == null ||
                    finalMinutes < 1 ||
                    finalMinutes > 180) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Zadej platný počet minut (1-180)'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Spustit novou session s custom duration
                ref.read(pomodoroProvider.notifier).add(
                      ContinuePomodoroEvent(
                        Duration(minutes: finalMinutes),
                      ),
                    );
                Navigator.pop(dialogContext);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('START'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
