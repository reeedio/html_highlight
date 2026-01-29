// ignore_for_file: avoid_print

import 'package:html_highlight/html_highlight.dart';

/// Example demonstrating the html_highlight package.
void main() {
  // Sample HTML content
  const html = '''
    <article>
      <h1>Welcome to html_highlight</h1>
      <p>This is a <strong>powerful</strong> highlighting engine for Flutter.</p>
      <blockquote>
        <p>It handles complex HTML structures with ease.</p>
      </blockquote>
      <ul>
        <li>DOM-based processing</li>
        <li>Multi-strategy resolution</li>
        <li>Cross-element highlights</li>
      </ul>
      <p>Try it out in your next project!</p>
    </article>
  ''';

  // Create the highlight engine
  final engine = HighlightEngine();

  // Example 1: Basic highlighting
  print('=== Example 1: Basic Highlighting ===\n');
  basicHighlightingExample(engine, html);

  // Example 2: Multiple highlights with different colors
  print('\n=== Example 2: Multiple Colors ===\n');
  multipleColorsExample(engine, html);

  // Example 3: Working with text maps
  print('\n=== Example 3: Text Maps ===\n');
  textMapExample(engine, html);

  // Example 4: JSON serialization
  print('\n=== Example 4: Serialization ===\n');
  serializationExample();
}

/// Demonstrates basic highlight application.
void basicHighlightingExample(HighlightEngine engine, String html) {
  // Create a highlight anchor
  final anchor = HighlightAnchor(
    id: 'highlight-1',
    articleId: 'example-article',
    startOffset: 30,
    endOffset: 38,
    exactText: 'powerful',
    prefixContext: 'This is a ',
    suffixContext: ' highlighting',
    color: HighlightColor.yellow,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Apply the highlight
  final result = engine.apply(html, [anchor]);

  // Check results
  print('Applied: ${result.applied} highlight(s)');
  print('Orphaned: ${result.orphanedCount} highlight(s)');
  print('All applied: ${result.allApplied}');

  // The result.html contains the highlighted HTML
  print('\nProcessed HTML preview:');
  print(result.html.substring(0, 200).replaceAll('\n', ' ').trim());
  print('...');
}

/// Demonstrates multiple highlights with different colors.
void multipleColorsExample(HighlightEngine engine, String html) {
  final highlights = [
    HighlightAnchor(
      id: 'hl-yellow',
      articleId: 'example',
      startOffset: 30,
      endOffset: 38,
      exactText: 'powerful',
      prefixContext: 'This is a ',
      suffixContext: ' highlighting',
      color: HighlightColor.yellow,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    HighlightAnchor(
      id: 'hl-blue',
      articleId: 'example',
      startOffset: 100,
      endOffset: 120,
      exactText: 'DOM-based processing',
      prefixContext: '',
      suffixContext: '',
      color: HighlightColor.blue,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    HighlightAnchor(
      id: 'hl-green',
      articleId: 'example',
      startOffset: 121,
      endOffset: 145,
      exactText: 'Multi-strategy resolution',
      prefixContext: '',
      suffixContext: '',
      color: HighlightColor.green,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  final result = engine.apply(html, highlights);

  print('Applied: ${result.applied} highlights');
  print('Colors used:');
  for (final hl in highlights) {
    print('  - ${hl.id}: ${hl.color.name}');
  }
}

/// Demonstrates working with text maps for creating new highlights.
void textMapExample(HighlightEngine engine, String html) {
  // Get the text map
  final textMap = engine.getTextMap(html, articleId: 'example');

  // Print plain text
  print('Plain text length: ${textMap.plainText.length} characters');
  print('Text nodes: ${textMap.textNodes.length}');

  // Find a specific position
  const position = 50;
  final domPos = textMap.plainTextToDom(position);

  if (domPos != null) {
    print('\nPosition $position maps to:');
    print('  Node path: ${domPos.node.path}');
    print('  Local offset: ${domPos.offset}');
    print('  Node text: "${domPos.node.text.substring(0, 20)}..."');
  }

  // Find nodes in a range
  final nodesInRange = textMap.getNodesInRange(0, 100);
  print('\nNodes in range 0-100: ${nodesInRange.length}');
}

/// Demonstrates JSON serialization for database storage.
void serializationExample() {
  // Create an anchor
  final anchor = HighlightAnchor(
    id: 'serialized-highlight',
    articleId: 'article-456',
    startOffset: 100,
    endOffset: 150,
    exactText: 'example text to highlight',
    prefixContext: 'Here is some ',
    suffixContext: ' in this document.',
    noteContent: 'This is my note about this highlight',
    color: HighlightColor.pink,
    createdAt: DateTime(2025, 1, 30, 10, 30),
    updatedAt: DateTime(2025, 1, 30, 10, 30),
    // V2 fields
    startNodePath: '/body/p[0]/text()[0]',
    startNodeOffset: 13,
    endNodePath: '/body/p[0]/text()[0]',
    endNodeOffset: 38,
    textFingerprint: 'abc123',
    schemaVersion: 2,
  );

  // Convert to JSON
  final json = anchor.toJson();
  print('Serialized to JSON:');
  print('  id: ${json['id']}');
  print('  article_id: ${json['article_id']}');
  print('  exact_text: ${json['exact_text']}');
  print('  color: ${json['color']}');
  print('  schema_version: ${json['schema_version']}');

  // Restore from JSON
  final restored = HighlightAnchor.fromJson(json);
  print('\nRestored from JSON:');
  print('  ID matches: ${restored.id == anchor.id}');
  print('  Text matches: ${restored.exactText == anchor.exactText}');
  print('  Has V2 data: ${restored.hasV2Data}');
}
