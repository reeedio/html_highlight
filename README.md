# html_highlight

[![Package Version](https://img.shields.io/pub/v/html_highlight?color=teal)](https://pub.dev/packages/html_highlight "Published package version")
[![Style: Lints](https://img.shields.io/badge/style-lints-teal.svg)](https://github.com/dart-lang/lints "Package linter helper")
[![LICENSE](https://img.shields.io/badge/License-MIT-red.svg)](https://github.com/theiskaa/html_highlight#License "Project's LICENSE section")


<img align="right" width="300" alt="highlight" src="https://github.com/user-attachments/assets/6e6db63b-53b3-44eb-95e9-34e470ca39f0" />

html_highlight solves the challenge of adding persistent text highlights to HTML content in Flutter applications. Unlike simple string-based approaches that break on complex HTML, this package parses HTML into a DOM tree, manipulates it safely, and serializes it back—ensuring highlights work correctly across paragraphs, lists, blockquotes, and nested elements.

The engine is idempotent (safe to apply multiple times), deterministic (same input always produces the same output), and uses a multi-strategy resolution system to locate highlights even when document content changes slightly.

html_highlight is a core component in the Reeed mobile app. To experience its capabilities in a real-world application, visit [Reeed](https://reeed.io).

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  html_highlight: ^1.0.0
```

## Quick Start

```dart
import 'package:html_highlight/html_highlight.dart';

final engine = HighlightEngine();

final anchor = HighlightAnchor(
  id: 'highlight-1',
  articleId: 'article-123',
  startOffset: 100,
  endOffset: 150,
  exactText: 'highlighted text here',
  prefixContext: 'some context before ',
  suffixContext: ' some context after',
  color: HighlightColor.yellow,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

final result = engine.apply(htmlContent, [anchor]);

print('Applied: ${result.applied}, Orphaned: ${result.orphanedCount}');
// Use result.html for rendering
```

## How It Works

The engine processes highlights through a pipeline: first parsing HTML into a DOM tree, then removing any existing highlights for idempotency, building a text-to-DOM position map, resolving each highlight's location using multiple strategies, applying the highlights by wrapping text in custom elements, and finally serializing back to HTML.

When locating highlights, the engine tries three strategies in order. The primary strategy uses stored DOM paths (XPath-like paths such as `/body/p[0]/text()[0]`) for precise positioning. If that fails, it falls back to text position matching using the highlight's surrounding context. As a last resort, it performs a fuzzy search using text similarity scoring.

For highlights that span multiple HTML elements (like a selection from a blockquote into a list), the engine identifies all affected text nodes and wraps each portion separately with the same highlight ID, processing in reverse order to maintain position accuracy.

## Highlight Colors

The package includes eight predefined colors: `yellow`, `green`, `blue`, `pink`, `orange`, `purple`, `red`, and `cyan`. You can also create custom colors:

```dart
final coral = HighlightColor(hex: 'FF5733', name: 'coral');
```

## Schema Versions

Highlights support two schema versions for backward compatibility. Version 1 (legacy) uses only text-based anchoring with offsets and context. Version 2 adds DOM path information for precise node-level positioning. The engine handles both transparently, and new highlights automatically use version 2 when a text map is provided.

## Integration with flutter_html

To make highlights tappable, register a TagExtension for the custom highlight element:

```dart
Html(
  data: result.html,
  extensions: [
    TagExtension(
      tagsToExtend: {'html-hl'},
      builder: (context) {
        final hlId = context.attributes['data-hl-id'];
        return GestureDetector(
          onTap: () => onHighlightTapped(hlId),
          child: RichText(text: context.styledElement!.style),
        );
      },
    ),
  ],
)
```

## Persistence

Anchors serialize to JSON for database storage:

```dart
final json = anchor.toJson();
await database.insert('highlights', json);

final restored = HighlightAnchor.fromJson(json);
```

## Cache Management

The engine caches text maps for performance. Clear caches when content changes:

```dart
HighlightEngine.clearCache('article-123');  // Specific article
HighlightEngine.clearAllCache();            // All cached maps
```

## Contributing
For information regarding contributions, please refer to [CONTRIBUTING.md](CONTRIBUTING.md) file.
