import '../models/highlight_anchor.dart';
import '../models/highlight_result.dart';
import 'dom_processor.dart';
import 'highlight_applicator.dart';

/// A robust, DOM-based HTML highlighting engine.
///
/// Parses HTML into a DOM tree, resolves highlight positions using multiple
/// strategies, applies highlights by wrapping text in custom elements, and
/// serializes back to HTML. The engine is idempotent and deterministic.
class HighlightEngine {
  /// Creates a HighlightEngine with optional custom highlight tag.
  ///
  /// The default highlight tag is 'html-hl'.
  HighlightEngine({String highlightTag = 'html-hl'})
      : _processor = DomProcessor(highlightTag: highlightTag),
        _applicator = HighlightApplicator(highlightTag: highlightTag);

  final DomProcessor _processor;
  final HighlightApplicator _applicator;

  /// Cache for processed text maps.
  static final _textMapCache = <String, DomTextMap>{};
  static const _maxCacheSize = 20;

  /// Applies highlights to HTML content and returns a [HighlightResult].
  HighlightResult apply(
    String html,
    List<HighlightAnchor> highlights, {
    String? articleId,
    bool includeTextMap = false,
  }) {
    if (highlights.isEmpty) {
      return HighlightResult(
        html: html,
        applied: 0,
        orphanedIds: [],
        textMap: includeTextMap ? _buildTextMap(html, articleId) : null,
      );
    }

    final root = _processor.parse(html);
    _processor.removeHighlights(root);
    final textMap = _processor.buildTextMap(root);

    if (articleId != null) {
      _cacheTextMap(articleId, textMap);
    }

    final resolved = <ResolvedHighlight>[];
    final anchorMap = <String, HighlightAnchor>{};
    final orphanedIds = <String>[];

    for (final highlight in highlights) {
      final resolution = _resolveHighlight(highlight, textMap);
      if (resolution.isResolved) {
        resolved.add(resolution);
        anchorMap[highlight.id] = highlight;
      } else {
        orphanedIds.add(highlight.id);
      }
    }

    if (resolved.isEmpty) {
      return HighlightResult(
        html: _processor.serialize(root),
        applied: 0,
        orphanedIds: orphanedIds,
        textMap: includeTextMap ? textMap : null,
      );
    }

    final nonOverlapping = _removeOverlaps(resolved);
    nonOverlapping.sort((a, b) => b.startPosition.compareTo(a.startPosition));

    for (final resolution in nonOverlapping) {
      final anchor = anchorMap[resolution.anchorId]!;
      _applicator.apply(root, resolution, textMap, anchor);
    }

    final resultHtml = _processor.serialize(root);

    return HighlightResult(
      html: resultHtml,
      applied: nonOverlapping.length,
      orphanedIds: orphanedIds,
      textMap: includeTextMap ? textMap : null,
    );
  }

  /// Gets or builds a text map for the given HTML.
  DomTextMap getTextMap(String html, {String? articleId}) {
    return _buildTextMap(html, articleId);
  }

  /// Extracts plain text from HTML.
  ///
  /// This is a convenience method for getting just the text content.
  String extractPlainText(String html) {
    final root = _processor.parse(html);
    final textMap = _processor.buildTextMap(root);
    return textMap.plainText;
  }

  DomTextMap _buildTextMap(String html, String? articleId) {
    if (articleId != null && _textMapCache.containsKey(articleId)) {
      return _textMapCache[articleId]!;
    }

    final root = _processor.parse(html);
    _processor.removeHighlights(root); // Ensure clean state
    final textMap = _processor.buildTextMap(root);

    if (articleId != null) {
      _cacheTextMap(articleId, textMap);
    }

    return textMap;
  }

  /// Caches a text map with LRU eviction.
  void _cacheTextMap(String articleId, DomTextMap textMap) {
    if (_textMapCache.length >= _maxCacheSize) {
      final keysToRemove =
          _textMapCache.keys.take(_maxCacheSize ~/ 2).toList();
      for (final key in keysToRemove) {
        _textMapCache.remove(key);
      }
    }
    _textMapCache[articleId] = textMap;
  }

  /// Clears the text map cache for a specific article.
  static void clearCache(String articleId) {
    _textMapCache.remove(articleId);
  }

  /// Clears the entire text map cache.
  static void clearAllCache() {
    _textMapCache.clear();
  }

  /// Resolves a highlight's position using DOM path, text position, or fuzzy search.
  ResolvedHighlight _resolveHighlight(
    HighlightAnchor highlight,
    DomTextMap textMap,
  ) {
    if (highlight.startNodePath != null && highlight.endNodePath != null) {
      final result = _resolveByDomPath(highlight, textMap);
      if (result != null && result.confidence >= 0.9) {
        return result;
      }
    }

    final textResult = _resolveByTextPosition(highlight, textMap);
    if (textResult != null && textResult.confidence >= 0.7) {
      return textResult;
    }

    final contextResult = _resolveByContext(highlight, textMap);
    if (contextResult != null && contextResult.confidence >= 0.5) {
      return contextResult;
    }

    return ResolvedHighlight.failed(highlight.id);
  }

  /// Resolves using stored DOM path information.
  ResolvedHighlight? _resolveByDomPath(
    HighlightAnchor highlight,
    DomTextMap textMap,
  ) {
    final startPath = highlight.startNodePath!;
    final endPath = highlight.endNodePath!;

    final startNode = textMap.getNodeByPath(startPath);
    final endNode = textMap.getNodeByPath(endPath);

    if (startNode == null || endNode == null) return null;

    final startPos =
        startNode.plainTextStart + (highlight.startNodeOffset ?? 0);
    final endPos =
        endNode.plainTextStart + (highlight.endNodeOffset ?? endNode.text.length);

    if (startPos >= endPos || endPos > textMap.plainText.length) return null;

    final actualText = textMap.plainText.substring(startPos, endPos);
    final similarity = _calculateSimilarity(actualText, highlight.exactText);

    if (similarity < 0.7) return null;

    return ResolvedHighlight(
      anchorId: highlight.id,
      startPosition: startPos,
      endPosition: endPos,
      strategy: ResolutionStrategy.domPath,
      confidence: similarity,
    );
  }

  /// Resolves using text position and context matching.
  ResolvedHighlight? _resolveByTextPosition(
    HighlightAnchor highlight,
    DomTextMap textMap,
  ) {
    final plainText = textMap.plainText;

    final fullPattern =
        highlight.prefixContext + highlight.exactText + highlight.suffixContext;
    var index = plainText.indexOf(fullPattern);

    if (index != -1) {
      final start = index + highlight.prefixContext.length;
      final end = start + highlight.exactText.length;

      return ResolvedHighlight(
        anchorId: highlight.id,
        startPosition: start,
        endPosition: end,
        strategy: ResolutionStrategy.textPosition,
        confidence: 1.0,
      );
    }

    if (highlight.prefixContext.isNotEmpty) {
      final prefixPattern = highlight.prefixContext + highlight.exactText;
      index = plainText.indexOf(prefixPattern);
      if (index != -1) {
        return ResolvedHighlight(
          anchorId: highlight.id,
          startPosition: index + highlight.prefixContext.length,
          endPosition: index + prefixPattern.length,
          strategy: ResolutionStrategy.textPosition,
          confidence: 0.9,
        );
      }
    }

    if (highlight.suffixContext.isNotEmpty) {
      final suffixPattern = highlight.exactText + highlight.suffixContext;
      index = plainText.indexOf(suffixPattern);
      if (index != -1) {
        return ResolvedHighlight(
          anchorId: highlight.id,
          startPosition: index,
          endPosition: index + highlight.exactText.length,
          strategy: ResolutionStrategy.textPosition,
          confidence: 0.9,
        );
      }
    }

    final occurrences = _findAllOccurrences(plainText, highlight.exactText);
    if (occurrences.length == 1) {
      return ResolvedHighlight(
        anchorId: highlight.id,
        startPosition: occurrences.first,
        endPosition: occurrences.first + highlight.exactText.length,
        strategy: ResolutionStrategy.textPosition,
        confidence: 0.8,
      );
    }

    if (occurrences.isNotEmpty) {
      final closest = _findClosestToOffset(occurrences, highlight.startOffset);
      return ResolvedHighlight(
        anchorId: highlight.id,
        startPosition: closest,
        endPosition: closest + highlight.exactText.length,
        strategy: ResolutionStrategy.textPosition,
        confidence: 0.7,
      );
    }

    return null;
  }

  /// Resolves using fuzzy context search.
  ResolvedHighlight? _resolveByContext(
    HighlightAnchor highlight,
    DomTextMap textMap,
  ) {
    final plainText = textMap.plainText;
    final searchText = highlight.exactText;

    if (searchText.isEmpty) return null;

    final normalizedSearch = _normalizeWhitespace(searchText);

    int? bestPosition;
    var bestScore = 0.0;

    // Sliding window search
    for (var i = 0; i <= plainText.length - searchText.length; i++) {
      final candidate = plainText.substring(i, i + searchText.length);
      final textSimilarity = _calculateSimilarity(candidate, searchText);

      if (textSimilarity < 0.7) continue;

      // Score context match
      final contextScore = _scoreContext(plainText, i, highlight);
      final totalScore = (textSimilarity * 0.6) + (contextScore * 0.4);

      if (totalScore > bestScore) {
        bestScore = totalScore;
        bestPosition = i;
      }
    }

    if (bestPosition == null && normalizedSearch != searchText) {
      for (var i = 0; i <= plainText.length - normalizedSearch.length; i++) {
        final candidate = plainText.substring(i, i + normalizedSearch.length);
        final normalizedCandidate = _normalizeWhitespace(candidate);
        final textSimilarity =
            _calculateSimilarity(normalizedCandidate, normalizedSearch);

        if (textSimilarity < 0.7) continue;

        final contextScore = _scoreContext(plainText, i, highlight);
        final totalScore = (textSimilarity * 0.6) + (contextScore * 0.4);

        if (totalScore > bestScore) {
          bestScore = totalScore;
          bestPosition = i;
        }
      }
    }

    if (bestPosition != null && bestScore >= 0.5) {
      return ResolvedHighlight(
        anchorId: highlight.id,
        startPosition: bestPosition,
        endPosition: bestPosition + searchText.length,
        strategy: ResolutionStrategy.contextSearch,
        confidence: bestScore,
      );
    }

    return null;
  }

  /// Scores how well the context matches at a given position.
  double _scoreContext(String plainText, int position, HighlightAnchor anchor) {
    final endPos = position + anchor.exactText.length;

    final prefixStart =
        (position - anchor.prefixContext.length).clamp(0, position);
    final actualPrefix = plainText.substring(prefixStart, position);

    final suffixEnd =
        (endPos + anchor.suffixContext.length).clamp(endPos, plainText.length);
    final actualSuffix = plainText.substring(endPos, suffixEnd);

    final prefixScore = _calculateSimilarity(actualPrefix, anchor.prefixContext);
    final suffixScore = _calculateSimilarity(actualSuffix, anchor.suffixContext);

    return (prefixScore + suffixScore) / 2;
  }

  List<ResolvedHighlight> _removeOverlaps(List<ResolvedHighlight> highlights) {
    if (highlights.length <= 1) return highlights;

    final sorted = List<ResolvedHighlight>.from(highlights)
      ..sort((a, b) => a.startPosition.compareTo(b.startPosition));

    final result = <ResolvedHighlight>[sorted.first];

    for (var i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final last = result.last;

      if (current.startPosition >= last.endPosition) {
        result.add(current);
      }
    }

    return result;
  }

  /// Finds all occurrences of a string in text.
  List<int> _findAllOccurrences(String text, String search) {
    final occurrences = <int>[];
    var index = 0;

    while (true) {
      index = text.indexOf(search, index);
      if (index == -1) break;
      occurrences.add(index);
      index++;
    }

    return occurrences;
  }

  /// Finds the occurrence closest to the target offset.
  int _findClosestToOffset(List<int> occurrences, int targetOffset) {
    var closest = occurrences.first;
    var closestDistance = (closest - targetOffset).abs();

    for (final occurrence in occurrences) {
      final distance = (occurrence - targetOffset).abs();
      if (distance < closestDistance) {
        closest = occurrence;
        closestDistance = distance;
      }
    }

    return closest;
  }

  /// Calculates similarity between two strings (0.0 to 1.0).
  double _calculateSimilarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a == b) return 1.0;

    // Simple LCS-based similarity
    final lcsLength = _longestCommonSubsequence(a, b);
    return (2.0 * lcsLength) / (a.length + b.length);
  }

  /// Calculates the length of the longest common subsequence.
  int _longestCommonSubsequence(String a, String b) {
    final m = a.length;
    final n = b.length;

    // Use two rows instead of full matrix for memory efficiency
    var prev = List<int>.filled(n + 1, 0);
    var curr = List<int>.filled(n + 1, 0);

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          curr[j] = prev[j - 1] + 1;
        } else {
          curr[j] = curr[j - 1] > prev[j] ? curr[j - 1] : prev[j];
        }
      }
      final temp = prev;
      prev = curr;
      curr = temp;
      curr.fillRange(0, n + 1, 0);
    }

    return prev[n];
  }

  /// Normalizes whitespace in a string.
  String _normalizeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
