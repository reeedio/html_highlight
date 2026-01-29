import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import 'node_path.dart';

/// Information about a text node, including its position mappings.
class TextNodeInfo {
  /// Creates a new [TextNodeInfo] with the given parameters.
  const TextNodeInfo({
    required this.node,
    required this.path,
    required this.plainTextStart,
    required this.plainTextEnd,
    required this.text,
  });

  /// The DOM text node.
  final dom.Text node;

  /// The path to this node in the DOM tree.
  final NodePath path;

  /// The start position in the plain text representation.
  final int plainTextStart;

  /// The end position in the plain text representation.
  final int plainTextEnd;

  /// The text content of this node.
  final String text;

  /// The length of the text content.
  int get length => plainTextEnd - plainTextStart;

  /// Returns true if the given position is within this node's range.
  bool containsPosition(int position) {
    return position >= plainTextStart && position < plainTextEnd;
  }

  /// Returns true if this node overlaps with the given range.
  bool overlapsRange(int start, int end) {
    return plainTextEnd > start && plainTextStart < end;
  }

  @override
  String toString() {
    final preview = text.length > 20 ? '${text.substring(0, 20)}...' : text;
    return 'TextNodeInfo(plain: $plainTextStart-$plainTextEnd, '
        'path: $path, text: "$preview")';
  }
}

/// A map of the DOM's text content with bidirectional position mappings.
class DomTextMap {
  /// Creates a new [DomTextMap] with the given plain text and text nodes.
  DomTextMap({
    required this.plainText,
    required this.textNodes,
  }) : _nodeByPath = {for (final n in textNodes) n.path.toString(): n};

  /// The concatenated plain text from all text nodes.
  final String plainText;

  /// The list of text nodes with their position mappings.
  final List<TextNodeInfo> textNodes;

  final Map<String, TextNodeInfo> _nodeByPath;

  /// Returns the text node at the given path, or null if not found.
  TextNodeInfo? getNodeByPath(String path) => _nodeByPath[path];

  /// Returns all text nodes that overlap with the given range.
  List<TextNodeInfo> getNodesInRange(int start, int end) {
    return textNodes.where((node) => node.overlapsRange(start, end)).toList();
  }

  /// Finds the text node containing the given position.
  TextNodeInfo? findNodeAtPosition(int position) {
    for (final node in textNodes) {
      if (node.containsPosition(position)) return node;
    }
    return null;
  }

  /// Converts a plain text position to a DOM node and offset.
  ({TextNodeInfo node, int offset})? plainTextToDom(int position) {
    final node = findNodeAtPosition(position);
    if (node == null) return null;
    return (node: node, offset: position - node.plainTextStart);
  }

  /// Converts a DOM path and offset to a plain text position.
  int? domToPlainText(String path, int offset) {
    final node = _nodeByPath[path];
    if (node == null) return null;
    return node.plainTextStart + offset;
  }
}

/// Processes HTML content into a DOM tree and extracts text mappings.
class DomProcessor {
  /// Block-level elements that should have newlines added around them.
  static const _blockElements = {
    'p',
    'div',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'ul',
    'ol',
    'li',
    'blockquote',
    'pre',
    'hr',
    'br',
    'table',
    'thead',
    'tbody',
    'tr',
    'td',
    'th',
    'article',
    'section',
    'header',
    'footer',
    'nav',
    'aside',
    'figure',
    'figcaption',
    'address',
    'dd',
    'dt',
    'dl',
  };

  static const _skipElements = {'script', 'style', 'html-hl'};

  /// The tag name used for highlight elements.
  final String highlightTag;

  /// Creates a new [DomProcessor] with the given highlight tag.
  DomProcessor({this.highlightTag = 'html-hl'});

  /// Parses the given HTML string and returns the body element.
  dom.Element parse(String html) {
    final document = html_parser.parse(html);
    return document.body ?? document.documentElement!;
  }

  /// Serializes the given element to an HTML string.
  String serialize(dom.Element root) {
    return root.innerHtml;
  }

  /// Builds a text map from the given DOM tree.
  DomTextMap buildTextMap(dom.Element root) {
    final textNodes = <TextNodeInfo>[];
    final plainTextBuffer = StringBuffer();

    _traverse(root, textNodes, plainTextBuffer);

    return DomTextMap(
      plainText: plainTextBuffer.toString(),
      textNodes: textNodes,
    );
  }

  /// Removes all highlight elements from the given DOM tree.
  void removeHighlights(dom.Element root) {
    final highlights = <dom.Element>[];
    _findHighlightElements(root, highlights);

    for (final hl in highlights) {
      _unwrapElement(hl);
    }

    _normalizeTextNodes(root);
  }

  void _traverse(
    dom.Node node,
    List<TextNodeInfo> textNodes,
    StringBuffer plainText,
  ) {
    if (node is dom.Text) {
      final text = node.text;
      if (text.trim().isNotEmpty) {
        final path = NodePath.fromNode(node);

        textNodes.add(TextNodeInfo(
          node: node,
          path: path,
          plainTextStart: plainText.length,
          plainTextEnd: plainText.length + text.length,
          text: text,
        ));

        plainText.write(text);
      }
    } else if (node is dom.Element) {
      final tagName = node.localName?.toLowerCase();

      if (_skipElements.contains(tagName) || tagName == highlightTag) {
        return;
      }

      final isBlock = _blockElements.contains(tagName);
      if (isBlock &&
          plainText.isNotEmpty &&
          !plainText.toString().endsWith('\n')) {
        plainText.write('\n');
      }

      for (final child in node.nodes) {
        _traverse(child, textNodes, plainText);
      }

      if (isBlock &&
          plainText.isNotEmpty &&
          !plainText.toString().endsWith('\n')) {
        plainText.write('\n');
      }
    }
  }

  void _findHighlightElements(dom.Node node, List<dom.Element> highlights) {
    if (node is dom.Element) {
      final tagName = node.localName?.toLowerCase();

      if (tagName == highlightTag) {
        highlights.add(node);
      } else if (tagName == 'span' && node.attributes.containsKey('data-hl-id')) {
        highlights.add(node);
      }

      for (final child in node.nodes.toList()) {
        _findHighlightElements(child, highlights);
      }
    }
  }

  void _unwrapElement(dom.Element element) {
    final parent = element.parent;
    if (parent == null) return;

    final index = parent.nodes.indexOf(element);
    if (index == -1) return;

    final children = element.nodes.toList();
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      element.nodes.remove(child);
      parent.nodes.insert(index + i, child);
    }

    element.remove();
  }

  void _normalizeTextNodes(dom.Node node) {
    if (node is dom.Element) {
      final children = node.nodes.toList();

      for (var i = children.length - 1; i > 0; i--) {
        if (children[i] is dom.Text && children[i - 1] is dom.Text) {
          final combined =
              (children[i - 1] as dom.Text).text + (children[i] as dom.Text).text;

          (children[i - 1] as dom.Text).replaceWith(dom.Text(combined));
          children[i].remove();
        }
      }

      for (final child in node.nodes) {
        _normalizeTextNodes(child);
      }
    }
  }
}
