import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/pomodoro_bloc.dart';
import '../bloc/pomodoro_event.dart';
import '../bloc/pomodoro_state.dart';

/// Widget zobrazuj�c� historii Pomodoro sessions
class HistoryList extends StatefulWidget {
  const HistoryList({super.key});

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  @override
  void initState() {
    super.initState();
    // Na�st historii pYi inicializaci
    context.read<PomodoroBloc>().add(const LoadHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroBloc, PomodoroState>(
      buildWhen: (previous, current) =>
          previous.history != current.history ||
          previous.isLoading != current.isLoading,
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state.history.isEmpty) {
          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: const [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '}�dn� historie',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Spusete sv� prvn� Pomodoro!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '=� Historie (dnes)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),

                // Session list
                ...state.history.map((session) {
                  final timeFormat = DateFormat.Hm();
                  final startTime = timeFormat.format(session.startedAt);
                  final duration = session.actualDuration ?? session.duration;
                  final durationMin = duration.inMinutes;
                  final icon = session.completed ? '' : '�';
                  final typeIcon = session.isBreak ? '' : '<E';

                  return ListTile(
                    leading: Text(
                      typeIcon,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      '$startTime - $durationMin min',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('�kol #${session.taskId}'),
                    trailing: Text(
                      icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
