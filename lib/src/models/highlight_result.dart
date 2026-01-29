import '../engine/dom_processor.dart';

/// The result of applying highlights to HTML content.
class HighlightResult {
  /// Creates a new [HighlightResult] with the given parameters.
  const HighlightResult({
    required this.html,
    required this.applied,
    required this.orphanedIds,
    this.textMap,
  });

  /// The resulting HTML with highlights applied.
  final String html;

  /// The number of highlights successfully applied.
  final int applied;

  /// List of highlight IDs that could not be applied.
  final List<String> orphanedIds;

  /// The text map used for position resolution.
  final DomTextMap? textMap;

  /// The number of orphaned highlights.
  int get orphanedCount => orphanedIds.length;

  /// Returns true if all highlights were successfully applied.
  bool get allApplied => orphanedIds.isEmpty;

  /// The total number of highlights (applied + orphaned).
  int get total => applied + orphanedCount;

  @override
  String toString() =>
      'HighlightResult(applied: $applied, orphaned: $orphanedCount)';
}

/// The strategy used to resolve a highlight's position.
enum ResolutionStrategy {
  /// Resolved using DOM path (v2 schema).
  domPath,

  /// Resolved using text position offset.
  textPosition,

  /// Resolved using context search.
  contextSearch,

  /// Failed to resolve the highlight position.
  failed,
}

/// A resolved highlight with its position in the text map.
class ResolvedHighlight {
  /// Creates a new [ResolvedHighlight] with the given parameters.
  const ResolvedHighlight({
    required this.anchorId,
    required this.startPosition,
    required this.endPosition,
    required this.strategy,
    required this.confidence,
  });

  /// The ID of the highlight anchor.
  final String anchorId;

  /// The start position in the plain text.
  final int startPosition;

  /// The end position in the plain text.
  final int endPosition;

  /// The strategy used to resolve this highlight.
  final ResolutionStrategy strategy;

  /// The confidence level of the resolution (0.0 to 1.0).
  final double confidence;

  /// Returns true if this highlight was successfully resolved.
  bool get isResolved => strategy != ResolutionStrategy.failed;

  /// The length of the highlighted text.
  int get length => endPosition - startPosition;

  /// Creates a failed [ResolvedHighlight] for the given anchor ID.
  factory ResolvedHighlight.failed(String anchorId) {
    return ResolvedHighlight(
      anchorId: anchorId,
      startPosition: -1,
      endPosition: -1,
      strategy: ResolutionStrategy.failed,
      confidence: 0.0,
    );
  }

  @override
  String toString() =>
      'ResolvedHighlight($anchorId, $startPosition-$endPosition, $strategy, ${(confidence * 100).toStringAsFixed(0)}%)';
}
