import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/pomodoro_provider.dart';

/// Widget zobrazujici historii Pomodoro sessions
class HistoryList extends ConsumerStatefulWidget {
  const HistoryList({super.key});

  @override
  ConsumerState<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends ConsumerState<HistoryList> {
  @override
  void initState() {
    super.initState();
    // Nacist historii pri inicializaci
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pomodoroProvider.notifier).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pomodoroAsync = ref.watch(pomodoroProvider);

    return pomodoroAsync.when(
      data: (state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Pokud je historie prázdná, zobraz sbalený panel s hláškou
        if (state.history.isEmpty) {
          return Card(
            elevation: 2,
            child: ExpansionTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: const Text(
                'Historie (dnes)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Žádné sessions'),
              children: const [
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Spusťte své první Pomodoro!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Historie s daty - sbalitelný ExpansionTile
        return Card(
          elevation: 2,
          child: ExpansionTile(
            leading: const Icon(Icons.history),
            title: const Text(
              'Historie (dnes)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text('${state.history.length} sessions'),
            initiallyExpanded: false, // Výchozí stav: sbaleno
            children: state.history.map((session) {
              final timeFormat = DateFormat.Hm();
              final startTime = timeFormat.format(session.startedAt);
              final duration = session.actualDuration ?? session.duration;
              final durationMin = duration.inMinutes;
              final statusIcon = session.completed ? '✅' : '⏸️';
              final typeIcon = session.isBreak ? '☕' : '🍅';

              return ListTile(
                dense: true,
                leading: Text(
                  typeIcon,
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(
                  '$startTime - $durationMin min',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('Úkol #${session.taskId}'),
                trailing: Text(
                  statusIcon,
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
