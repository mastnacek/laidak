import 'package:objectbox/objectbox.dart';

/// ObjectBox entita pro Note embeddings
///
/// Hybrid architektura:
/// - SQLite (DatabaseHelper) = source of truth pro Note data
/// - ObjectBox (VectorStore) = vector search layer pro semantic search
///
/// Partition keys optimization:
/// - `isFavourite` index → filter oblíbené vs běžné poznámky
///
/// Model: paraphrase-multilingual-MiniLM-L12-v2 (ONNX)
/// - 384 dimensions
/// - 50+ languages (včetně češtiny)
@Entity()
class NoteEmbedding {
  /// ObjectBox ID (auto-generated)
  @Id()
  int id = 0;

  /// Reference na SQLite note.id
  @Index()
  int noteId;

  /// Vector embedding (384-dim float array)
  @HnswIndex(dimensions: 384, distanceType: VectorDistanceType.cosine)
  @Property(type: PropertyType.floatVector)
  List<double> embedding;

  /// Partition key: isFavourite (Tauri optimization pro Notes)
  ///
  /// Dělí databázi na:
  /// - favourite (true) → oblíbené poznámky
  /// - regular (false) → běžné poznámky
  @Index()
  bool isFavourite;

  /// Auxiliary data: text preview (prvních 100 znaků)
  String textPreview;

  /// Metadata: embedding model name
  String modelName;

  /// Metadata: kdy byl embedding vytvořen
  DateTime embeddedAt;

  /// Constructor
  NoteEmbedding({
    required this.noteId,
    required this.embedding,
    required this.isFavourite,
    required this.textPreview,
    required this.modelName,
    required this.embeddedAt,
  });

  /// Factory: Create from SQLite Note data
  factory NoteEmbedding.fromNoteData({
    required int noteId,
    required List<double> embedding,
    required String noteContent,
    required bool isFavourite,
    required String modelName,
  }) {
    return NoteEmbedding(
      noteId: noteId,
      embedding: embedding,
      isFavourite: isFavourite,
      textPreview:
          noteContent.length > 100 ? noteContent.substring(0, 100) : noteContent,
      modelName: modelName,
      embeddedAt: DateTime.now(),
    );
  }
}
