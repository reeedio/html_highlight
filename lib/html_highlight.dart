/// A robust, DOM-based HTML highlighting engine for Flutter.
///
/// This package provides a production-ready solution for adding persistent
/// highlights to HTML content. It handles complex HTML structures including
/// lists, blockquotes, code blocks, and nested elements.
///
/// ## Features
///
/// - **DOM-based processing**: Parses HTML into a DOM tree for reliable manipulation
/// - **Multi-strategy resolution**: Uses DOM paths, text positions, and fuzzy matching
/// - **Idempotent**: Safe to apply multiple times without corruption
/// - **Cross-element highlights**: Supports selections spanning multiple HTML elements
/// - **Custom styling**: Configurable colors and appearance
/// - **Persistent anchoring**: Highlights can be saved and restored from storage
///
/// ## Quick Start
///
/// ```dart
/// import 'package:html_highlight/html_highlight.dart';
///
/// // Create the engine
/// final engine = HighlightEngine();
///
/// // Create a highlight anchor
/// final anchor = HighlightAnchor(
///   id: 'highlight-1',
///   articleId: 'article-123',
///   startOffset: 100,
///   endOffset: 150,
///   exactText: 'highlighted text',
///   prefixContext: 'some text before ',
///   suffixContext: ' some text after',
///   color: HighlightColor.yellow,
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
///
/// // Apply highlights to HTML
/// final result = engine.apply(htmlContent, [anchor]);
///
/// // Use the result
/// print('Applied: ${result.applied} highlights');
/// print('Orphaned: ${result.orphanedCount} highlights');
/// displayHtml(result.html);
/// ```
///
/// ## Architecture
///
/// The package uses a pipeline architecture:
///
/// 1. **Parsing**: HTML is parsed into a DOM tree using the `html` package
/// 2. **Text Mapping**: Plain text is extracted with bidirectional position mappings
/// 3. **Resolution**: Each highlight's position is resolved using multiple strategies
/// 4. **Application**: Highlights are applied by wrapping text in custom elements
/// 5. **Serialization**: The modified DOM is serialized back to HTML
///
/// ## Highlight Resolution Strategies
///
/// The engine uses a cascade of strategies to locate highlights:
///
/// 1. **DOM Path** (highest confidence): Uses stored XPath-like paths to text nodes
/// 2. **Text Position**: Matches text with surrounding context
/// 3. **Fuzzy Search**: Falls back to similarity-based matching
///
/// This multi-strategy approach ensures highlights can be found even when
/// document content changes slightly.
///
/// ## Custom Element
///
/// By default, highlights are wrapped in `<html-hl>` elements with inline styles.
/// Inside `<a>` tags, `<span>` is used to avoid nesting violations.
///
/// The custom element includes:
/// - `data-hl-id`: The highlight's unique identifier
/// - `style`: Background color and styling
///
/// ## See Also
///
/// - [HighlightEngine] - The main engine class
/// - [HighlightAnchor] - Model for highlight data
/// - [HighlightResult] - Result of applying highlights
/// - [DomTextMap] - Text-to-DOM position mapping
library html_highlight;

export 'src/engine/engine.dart';
export 'src/models/models.dart';
