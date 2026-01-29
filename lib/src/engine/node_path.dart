import 'package:html/dom.dart' as dom;

/// Represents a segment in a DOM node path (element or text node).
class PathSegment {
  /// Creates a path segment for an element with the given tag and index.
  const PathSegment.element(this.tag, this.index);

  /// Creates a path segment for a text node with the given index.
  const PathSegment.text(this.index) : tag = null;

  /// The tag name for element segments, or null for text segments.
  final String? tag;

  /// The index of this segment among siblings of the same type.
  final int index;

  /// Returns true if this is a text node segment.
  bool get isText => tag == null;

  /// Returns true if this is an element segment.
  bool get isElement => tag != null;

  @override
  String toString() => isText ? '/text()[$index]' : '/$tag[$index]';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PathSegment && other.tag == tag && other.index == index;
  }

  @override
  int get hashCode => Object.hash(tag, index);
}

/// Represents a deterministic path to a DOM node (XPath-like format).
class NodePath {
  /// Creates a new [NodePath] with the given segments.
  const NodePath(this.segments);

  /// Creates an empty node path.
  const NodePath.empty() : segments = const [];

  /// The list of path segments from root to target node.
  final List<PathSegment> segments;

  /// Creates a [NodePath] from a DOM node by traversing up to the root.
  factory NodePath.fromNode(dom.Node node) {
    final segments = <PathSegment>[];
    var current = node;

    while (current.parent != null) {
      final parent = current.parent!;

      if (parent is dom.Document) break;
      if (parent is dom.Element && parent.localName?.toLowerCase() == 'html') {
        break;
      }

      if (current is dom.Text) {
        final index = _textNodeIndex(current, parent);
        segments.insert(0, PathSegment.text(index));
      } else if (current is dom.Element) {
        final tag = current.localName!.toLowerCase();
        final index = _elementIndex(current, parent);
        segments.insert(0, PathSegment.element(tag, index));
      }

      current = parent;
    }

    return NodePath(segments);
  }

  /// Parses a path string into a [NodePath].
  factory NodePath.parse(String pathString) {
    if (pathString.isEmpty) {
      return const NodePath.empty();
    }

    final segments = <PathSegment>[];
    final parts = pathString.split('/').where((p) => p.isNotEmpty).toList();

    for (final part in parts) {
      if (part == 'body') continue;

      if (part.startsWith('text()')) {
        final indexMatch = RegExp(r'\[(\d+)\]').firstMatch(part);
        final index = indexMatch != null ? int.parse(indexMatch.group(1)!) : 0;
        segments.add(PathSegment.text(index));
      } else {
        final match = RegExp(r'(\w+)\[(\d+)\]').firstMatch(part);
        if (match != null) {
          final tag = match.group(1)!;
          final index = int.parse(match.group(2)!);
          segments.add(PathSegment.element(tag, index));
        }
      }
    }

    return NodePath(segments);
  }

  /// Resolves this path to a DOM node starting from the given root element.
  dom.Node? resolve(dom.Element root) {
    dom.Node current = root;

    for (final segment in segments) {
      if (segment.isText) {
        final textNode = _findTextChild(current, segment.index);
        if (textNode == null) return null;
        current = textNode;
      } else {
        final element = _findElementChild(current, segment.tag!, segment.index);
        if (element == null) return null;
        current = element;
      }
    }

    return current;
  }

  @override
  String toString() {
    if (segments.isEmpty) return '/body';
    return '/body${segments.map((s) => s.toString()).join('')}';
  }

  /// Returns true if this path has no segments.
  bool get isEmpty => segments.isEmpty;

  /// Returns true if this path has one or more segments.
  bool get isNotEmpty => segments.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NodePath) return false;
    if (segments.length != other.segments.length) return false;
    for (var i = 0; i < segments.length; i++) {
      if (segments[i] != other.segments[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(segments);

  static int _textNodeIndex(dom.Text node, dom.Node parent) {
    var index = 0;
    for (final sibling in parent.nodes) {
      if (sibling == node) return index;
      if (sibling is dom.Text && sibling.text.trim().isNotEmpty) {
        index++;
      }
    }
    return index;
  }

  static int _elementIndex(dom.Element node, dom.Node parent) {
    final tag = node.localName!.toLowerCase();
    var index = 0;
    for (final sibling in parent.nodes) {
      if (sibling == node) return index;
      if (sibling is dom.Element && sibling.localName?.toLowerCase() == tag) {
        index++;
      }
    }
    return index;
  }

  static dom.Text? _findTextChild(dom.Node parent, int targetIndex) {
    var index = 0;
    for (final child in parent.nodes) {
      if (child is dom.Text && child.text.trim().isNotEmpty) {
        if (index == targetIndex) return child;
        index++;
      }
    }
    return null;
  }

  static dom.Element? _findElementChild(
    dom.Node parent,
    String tag,
    int targetIndex,
  ) {
    var index = 0;
    for (final child in parent.nodes) {
      if (child is dom.Element && child.localName?.toLowerCase() == tag) {
        if (index == targetIndex) return child;
        index++;
      }
    }
    return null;
  }
}
