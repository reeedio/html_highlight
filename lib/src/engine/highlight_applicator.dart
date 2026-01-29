import 'package:html/dom.dart' as dom;

import '../models/highlight_anchor.dart';
import '../models/highlight_result.dart';
import 'dom_processor.dart';

/// Result of splitting a text node at highlight boundaries.
class SplitResult {
  /// Creates a split result.
  const SplitResult(this.before, this.middle, this.after);

  /// Text before the highlighted portion.
  final String before;

  /// The highlighted text.
  final String middle;

  /// Text after the highlighted portion.
  final String after;
}

/// Applies highlights to a DOM tree by wrapping text in highlight elements.
///
/// Handles single-node highlights, cross-node highlights spanning multiple
/// text nodes, highlights inside `<a>` tags (uses `<span>` to avoid nesting
/// violations), and highlights inside code blocks (background-only styling).
class HighlightApplicator {
  /// Creates a HighlightApplicator with optional custom tag name.
  ///
  /// The default highlight tag is 'html-hl'.
  HighlightApplicator({this.highlightTag = 'html-hl'});

  /// The custom tag name for highlight elements.
  final String highlightTag;

  /// Background opacity for normal highlights.
  final double normalOpacity = 0.4;

  /// Background opacity for highlights in code blocks.
  final double codeOpacity = 0.3;

  /// Applies a single resolved highlight to the DOM in place.
  void apply(
    dom.Element root,
    ResolvedHighlight resolution,
    DomTextMap textMap,
    HighlightAnchor anchor,
  ) {
    if (!resolution.isResolved) return;

    final affectedNodes = textMap.getNodesInRange(
      resolution.startPosition,
      resolution.endPosition,
    );

    if (affectedNodes.isEmpty) return;

    if (affectedNodes.length == 1) {
      _applySingleNode(affectedNodes.first, resolution, anchor);
      return;
    }

    _applyMultiNode(affectedNodes, resolution, anchor);
  }

  void _applySingleNode(
    TextNodeInfo nodeInfo,
    ResolvedHighlight resolution,
    HighlightAnchor anchor,
  ) {
    final node = nodeInfo.node;
    final localStart = resolution.startPosition - nodeInfo.plainTextStart;
    final localEnd = resolution.endPosition - nodeInfo.plainTextStart;

    final safeStart = localStart.clamp(0, nodeInfo.text.length);
    final safeEnd = localEnd.clamp(safeStart, nodeInfo.text.length);

    if (safeStart >= safeEnd) return;

    final parts = _splitText(node.text, safeStart, safeEnd);

    final insideAnchor = _isInsideAnchorTag(node);
    final insideCode = _isInsideCodeBlock(node);
    final wrapper = _createHighlightElement(anchor, insideAnchor, insideCode);
    wrapper.append(dom.Text(parts.middle));

    final parent = node.parent!;
    final index = parent.nodes.indexOf(node);

    node.remove();

    var insertIndex = index;
    if (parts.before.isNotEmpty) {
      parent.nodes.insert(insertIndex, dom.Text(parts.before));
      insertIndex++;
    }
    parent.nodes.insert(insertIndex, wrapper);
    insertIndex++;
    if (parts.after.isNotEmpty) {
      parent.nodes.insert(insertIndex, dom.Text(parts.after));
    }
  }

  void _applyMultiNode(
    List<TextNodeInfo> nodes,
    ResolvedHighlight resolution,
    HighlightAnchor anchor,
  ) {
    for (var i = nodes.length - 1; i >= 0; i--) {
      final nodeInfo = nodes[i];
      final isFirst = i == 0;
      final isLast = i == nodes.length - 1;

      var localStart = 0;
      var localEnd = nodeInfo.text.length;

      if (isFirst) {
        localStart = resolution.startPosition - nodeInfo.plainTextStart;
      }
      if (isLast) {
        localEnd = resolution.endPosition - nodeInfo.plainTextStart;
      }

      final safeStart = localStart.clamp(0, nodeInfo.text.length);
      final safeEnd = localEnd.clamp(safeStart, nodeInfo.text.length);

      if (safeStart >= safeEnd) continue;

      final node = nodeInfo.node;
      final parts = _splitText(node.text, safeStart, safeEnd);

      final insideAnchor = _isInsideAnchorTag(node);
      final insideCode = _isInsideCodeBlock(node);
      final wrapper = _createHighlightElement(anchor, insideAnchor, insideCode);
      wrapper.append(dom.Text(parts.middle));

      final parent = node.parent;
      if (parent == null) continue;

      final index = parent.nodes.indexOf(node);
      if (index == -1) continue;

      node.remove();

      var insertIndex = index;
      if (parts.before.isNotEmpty) {
        parent.nodes.insert(insertIndex, dom.Text(parts.before));
        insertIndex++;
      }
      parent.nodes.insert(insertIndex, wrapper);
      insertIndex++;
      if (parts.after.isNotEmpty) {
        parent.nodes.insert(insertIndex, dom.Text(parts.after));
      }
    }
  }

  SplitResult _splitText(String text, int start, int end) {
    return SplitResult(
      text.substring(0, start),
      text.substring(start, end),
      text.substring(end),
    );
  }

  dom.Element _createHighlightElement(
    HighlightAnchor anchor,
    bool insideAnchor,
    bool insideCode,
  ) {
    final tagName = insideAnchor ? 'span' : highlightTag;
    final element = dom.Element.tag(tagName);

    element.attributes['data-hl-id'] = anchor.id;

    final rgb = anchor.color.toRgb();

    String style;
    if (insideCode) {
      style = 'background-color:rgba(${rgb.r},${rgb.g},${rgb.b},$codeOpacity);';
    } else {
      style = 'background-color:rgba(${rgb.r},${rgb.g},${rgb.b},$normalOpacity);'
          'border-radius:2px;'
          'padding:0 2px;';
    }

    element.attributes['style'] = style;

    return element;
  }

  bool _isInsideAnchorTag(dom.Node node) {
    var current = node.parent;
    while (current != null) {
      if (current is dom.Element && current.localName?.toLowerCase() == 'a') {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  bool _isInsideCodeBlock(dom.Node node) {
    var current = node.parent;
    while (current != null) {
      if (current is dom.Element) {
        final tag = current.localName?.toLowerCase();
        if (tag == 'pre' || tag == 'code') {
          return true;
        }
      }
      current = current.parent;
    }
    return false;
  }
}
