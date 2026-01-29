import 'highlight_color.dart';

/// Represents a highlight anchor for locating and rendering a highlight in HTML.
///
/// Uses a multi-strategy approach: DOM path (v2), text position, or context search.
class HighlightAnchor {
  /// Creates a new [HighlightAnchor] with the given parameters.
  const HighlightAnchor({
    required this.id,
    required this.articleId,
    required this.startOffset,
    required this.endOffset,
    required this.exactText,
    required this.prefixContext,
    required this.suffixContext,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.noteContent,
    this.startNodePath,
    this.startNodeOffset,
    this.endNodePath,
    this.endNodeOffset,
    this.textFingerprint,
    this.schemaVersion = 1,
  });

  /// The unique identifier for this highlight.
  final String id;

  /// The identifier of the article containing this highlight.
  final String articleId;

  /// The start offset in the plain text.
  final int startOffset;

  /// The end offset in the plain text.
  final int endOffset;

  /// The exact text that was highlighted.
  final String exactText;

  /// Text before the highlight for context matching.
  final String prefixContext;

  /// Text after the highlight for context matching.
  final String suffixContext;

  /// Optional note content attached to this highlight.
  final String? noteContent;

  /// The color of this highlight.
  final HighlightColor color;

  /// The timestamp when this highlight was created.
  final DateTime createdAt;

  /// The timestamp when this highlight was last updated.
  final DateTime updatedAt;

  /// The DOM path to the start node (v2 schema).
  final String? startNodePath;

  /// The offset within the start node (v2 schema).
  final int? startNodeOffset;

  /// The DOM path to the end node (v2 schema).
  final String? endNodePath;

  /// The offset within the end node (v2 schema).
  final int? endNodeOffset;

  /// A fingerprint of the text for verification.
  final String? textFingerprint;

  /// The schema version for this highlight anchor.
  final int schemaVersion;

  /// Returns true if this anchor has v2 DOM path data.
  bool get hasV2Data =>
      startNodePath != null &&
      endNodePath != null &&
      startNodeOffset != null &&
      endNodeOffset != null;

  /// The length of the highlighted text.
  int get length => endOffset - startOffset;

  /// Creates a copy of this anchor with the given fields replaced.
  HighlightAnchor copyWith({
    String? id,
    String? articleId,
    int? startOffset,
    int? endOffset,
    String? exactText,
    String? prefixContext,
    String? suffixContext,
    String? noteContent,
    HighlightColor? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? startNodePath,
    int? startNodeOffset,
    String? endNodePath,
    int? endNodeOffset,
    String? textFingerprint,
    int? schemaVersion,
  }) {
    return HighlightAnchor(
      id: id ?? this.id,
      articleId: articleId ?? this.articleId,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      exactText: exactText ?? this.exactText,
      prefixContext: prefixContext ?? this.prefixContext,
      suffixContext: suffixContext ?? this.suffixContext,
      noteContent: noteContent ?? this.noteContent,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startNodePath: startNodePath ?? this.startNodePath,
      startNodeOffset: startNodeOffset ?? this.startNodeOffset,
      endNodePath: endNodePath ?? this.endNodePath,
      endNodeOffset: endNodeOffset ?? this.endNodeOffset,
      textFingerprint: textFingerprint ?? this.textFingerprint,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  /// Converts this anchor to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'article_id': articleId,
        'start_offset': startOffset,
        'end_offset': endOffset,
        'exact_text': exactText,
        'prefix_context': prefixContext,
        'suffix_context': suffixContext,
        'note_content': noteContent,
        'color': color.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'start_node_path': startNodePath,
        'start_node_offset': startNodeOffset,
        'end_node_path': endNodePath,
        'end_node_offset': endNodeOffset,
        'text_fingerprint': textFingerprint,
        'schema_version': schemaVersion,
      };

  /// Creates a [HighlightAnchor] from a JSON map.
  factory HighlightAnchor.fromJson(Map<String, dynamic> json) {
    return HighlightAnchor(
      id: json['id'] as String,
      articleId: json['article_id'] as String,
      startOffset: json['start_offset'] as int,
      endOffset: json['end_offset'] as int,
      exactText: json['exact_text'] as String,
      prefixContext: json['prefix_context'] as String,
      suffixContext: json['suffix_context'] as String,
      noteContent: json['note_content'] as String?,
      color: HighlightColor.fromName(json['color'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      startNodePath: json['start_node_path'] as String?,
      startNodeOffset: json['start_node_offset'] as int?,
      endNodePath: json['end_node_path'] as String?,
      endNodeOffset: json['end_node_offset'] as int?,
      textFingerprint: json['text_fingerprint'] as String?,
      schemaVersion: json['schema_version'] as int? ?? 1,
    );
  }

  @override
  String toString() =>
      'HighlightAnchor(id: $id, text: "${exactText.length > 20 ? '${exactText.substring(0, 20)}...' : exactText}")';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HighlightAnchor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
