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

        // Žluto-oranžová barva pro progress ring (stejná jako text)
        const progressColor = Color(0xFFFFB800); // jasně žlutá
        const progressGlowColor = Color(0xFFFF8800); // žluto-oranžová pro glow

        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular progress indicator s glow efektem
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: state.progress,
                  strokeWidth: 8, // o něco tlustší pro lepší viditelnost
                  backgroundColor: progressColor.withOpacity(0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(progressColor),
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
                      // Fixní žluto-oranžová barva (vždy výrazná)
                      color: const Color(0xFFFFB800), // jasně žlutá
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                      // Intenzivní žluto-oranžový glow efekt
                      shadows: [
                        // Vnější glow - oranžový
                        Shadow(
                          blurRadius: 30,
                          color: const Color(0xFFFF6B00).withOpacity(0.8), // oranžová
                          offset: const Offset(0, 0),
                        ),
                        // Střední glow - žluto-oranžový
                        Shadow(
                          blurRadius: 20,
                          color: const Color(0xFFFF8800).withOpacity(0.9), // žluto-oranžová
                          offset: const Offset(0, 0),
                        ),
                        // Blízký glow - jasně žlutý
                        Shadow(
                          blurRadius: 10,
                          color: const Color(0xFFFFB800), // jasně žlutá
                          offset: const Offset(0, 0),
                        ),
                        // Extra ostrý glow pro maximální kontrast
                        Shadow(
                          blurRadius: 5,
                          color: const Color(0xFFFFC800), // světle žlutá
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Label (Prace / Prestavka) - kompaktni
                  Text(
                    state.isBreak ? 'Prestavka' : 'Prace',
                    style: TextStyle(
                      fontSize: 14,
                      color: progressColor.withOpacity(0.6),
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
