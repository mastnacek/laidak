import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/pomodoro_bloc.dart';
import '../bloc/pomodoro_state.dart';
import '../../domain/entities/timer_state.dart';

/// Widget zobrazující velký časovač s circular progressem
class TimerDisplay extends StatelessWidget {
  const TimerDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroBloc, PomodoroState>(
      buildWhen: (previous, current) =>
          previous.remainingTime != current.remainingTime ||
          previous.timerState != current.timerState ||
          previous.progress != current.progress,
      builder: (context, state) {
        final timeText = state.formattedRemainingTime;
        
        // Barva podle typu (práce vs přestávka)
        final color = state.isBreak
            ? Colors.green
            : Theme.of(context).primaryColor;

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular progress indicator (mensi velikost)
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: state.progress,
                  strokeWidth: 6,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),

              // Timer text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Label (Prace / Prestavka) - kompaktni
                  Text(
                    state.isBreak ? 'Prestavka' : 'Prace',
                    style: TextStyle(
                      fontSize: 14,
                      color: color.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  // Status (Běží / Pozastaveno)
                  if (state.timerState == TimerState.paused)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '⏸️ Pozastaveno',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
