import 'package:objectbox/objectbox.dart';

/// ObjectBox entita pro TODO embeddings
///
/// Hybrid architektura:
/// - SQLite (DatabaseHelper) = source of truth pro TODO data
/// - ObjectBox (VectorStore) = vector search layer pro semantic search
///
/// Partition keys optimization (z Tauri projektu):
/// - `status` index → filter "pending" vs "completed" před vector search (10x rychlejší)
/// - `priority` index → filter high-priority tasks
///
/// Model: paraphrase-multilingual-MiniLM-L12-v2 (ONNX)
/// - 384 dimensions
/// - 50+ languages (včetně češtiny)
/// - Cosine similarity distance
@Entity()
class TodoEmbedding {
  /// ObjectBox ID (auto-generated)
  @Id()
  int id = 0;

  /// Reference na SQLite todo.id (KRITICKÉ pro propojení s DatabaseHelper)
  @Index()
  int todoId;

  /// Vector embedding (384-dim float array)
  ///
  /// HNSW index pro fast nearest neighbor search:
  /// - Cosine similarity (nejlepší pro text embeddings)
  /// - Query performance: <10ms pro 1000 TODOs
  @HnswIndex(dimensions: 384, distanceType: VectorDistanceType.cosine)
  @Property(type: PropertyType.floatVector)
  List<double> embedding;

  /// Partition key: status (Tauri optimization)
  ///
  /// Dělí databázi na segmenty:
  /// - "pending" → aktivní úkoly
  /// - "completed" → hotové úkoly
  ///
  /// Query může filtrovat před vector search → 10x rychlejší!
  @Index()
  String status;

  /// Partition key: priority (A/B/C filtering)
  @Index()
  String? priority;

  /// Auxiliary data: text preview (prvních 100 znaků)
  ///
  /// Eliminuje nutnost JOINu do SQLite pro zobrazení preview
  /// (Tauri pattern - auxiliary column optimization)
  String textPreview;

  /// Metadata: embedding model name
  String modelName; // "paraphrase-multilingual-minilm-l12-v2-onnx-q"

  /// Metadata: kdy byl embedding vytvořen
  DateTime embeddedAt;

  /// Constructor
  TodoEmbedding({
    required this.todoId,
    required this.embedding,
    required this.status,
    this.priority,
    required this.textPreview,
    required this.modelName,
    required this.embeddedAt,
  });

  /// Factory: Create from SQLite TODO data
  factory TodoEmbedding.fromTodoData({
    required int todoId,
    required List<double> embedding,
    required String todoText,
    required String status,
    String? priority,
    required String modelName,
  }) {
    return TodoEmbedding(
      todoId: todoId,
      embedding: embedding,
      status: status,
      priority: priority,
      textPreview:
          todoText.length > 100 ? todoText.substring(0, 100) : todoText,
      modelName: modelName,
      embeddedAt: DateTime.now(),
    );
  }
}
