/// A color representation for highlights with hex value and RGBA conversion.
class HighlightColor {
  /// Creates a new [HighlightColor] with the given hex value and name.
  const HighlightColor({
    required this.hex,
    required this.name,
  });

  /// The hex color value without the leading '#'.
  final String hex;

  /// The name of this color.
  final String name;

  /// Predefined yellow highlight color.
  static const yellow = HighlightColor(hex: 'FFF176', name: 'yellow');

  /// Predefined green highlight color.
  static const green = HighlightColor(hex: 'AED581', name: 'green');

  /// Predefined blue highlight color.
  static const blue = HighlightColor(hex: '81D4FA', name: 'blue');

  /// Predefined pink highlight color.
  static const pink = HighlightColor(hex: 'F48FB1', name: 'pink');

  /// Predefined orange highlight color.
  static const orange = HighlightColor(hex: 'FFCC80', name: 'orange');

  /// Predefined purple highlight color.
  static const purple = HighlightColor(hex: 'CE93D8', name: 'purple');

  /// Predefined red highlight color.
  static const red = HighlightColor(hex: 'EF9A9A', name: 'red');

  /// Predefined cyan highlight color.
  static const cyan = HighlightColor(hex: '80DEEA', name: 'cyan');

  /// List of all predefined highlight colors.
  static const List<HighlightColor> values = [
    yellow,
    green,
    blue,
    pink,
    orange,
    purple,
    red,
    cyan,
  ];

  /// Returns a [HighlightColor] by name, or yellow if not found.
  static HighlightColor fromName(String name) {
    return values.firstWhere(
      (c) => c.name == name,
      orElse: () => yellow,
    );
  }

  /// Converts the hex color to RGB components.
  ({int r, int g, int b}) toRgb() {
    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);
    return (r: r, g: g, b: b);
  }

  /// Converts the hex color to an RGBA string with the given alpha.
  String toRgba(double alpha) {
    final rgb = toRgb();
    return 'rgba(${rgb.r},${rgb.g},${rgb.b},$alpha)';
  }

  @override
  String toString() => 'HighlightColor($name, #$hex)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HighlightColor && other.hex == hex && other.name == name;
  }

  @override
  int get hashCode => Object.hash(hex, name);

  /// Converts this color to a JSON map.
  Map<String, dynamic> toJson() => {
        'hex': hex,
        'name': name,
      };

  /// Creates a [HighlightColor] from a JSON map.
  factory HighlightColor.fromJson(Map<String, dynamic> json) {
    return HighlightColor(
      hex: json['hex'] as String,
      name: json['name'] as String,
    );
  }
}
