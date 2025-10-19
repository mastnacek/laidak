import 'package:equatable/equatable.dart';

/// Parsed AI response
/// Strukturovaná odpověď z AI obsahující podúkoly, doporučení a analýzu termínu
class AiSplitResponse extends Equatable {
  final List<String> subtasks;
  final String recommendations;
  final String deadlineAnalysis;

  const AiSplitResponse({
    required this.subtasks,
    required this.recommendations,
    required this.deadlineAnalysis,
  });

  @override
  List<Object?> get props => [
        subtasks,
        recommendations,
        deadlineAnalysis,
      ];
}
