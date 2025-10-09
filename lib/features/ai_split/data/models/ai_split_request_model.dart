import '../../domain/entities/ai_split_request.dart';

/// Request model - pro JSON serialization
/// DTO pro komunikaci s OpenRouter API
class AiSplitRequestModel extends AiSplitRequest {
  const AiSplitRequestModel({
    required super.taskText,
    super.priority,
    super.deadline,
    super.tags,
    super.userNote,
  });

  /// Konverze do JSON pro API request
  Map<String, dynamic> toJson() {
    return {
      'taskText': taskText,
      if (priority != null) 'priority': priority,
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      'tags': tags,
      if (userNote != null) 'userNote': userNote,
    };
  }
}
