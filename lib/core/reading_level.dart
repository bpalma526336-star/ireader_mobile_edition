/// Phil-IRI reading level helpers shared by every role's read-record screens.
abstract final class ReadingLevel {
  static const independent = 'Independent';
  static const instructional = 'Instructional';
  static const frustration = 'Frustration';

  /// Word-reading accuracy as a whole percentage, clamped to 0–100.
  /// Returns 0 when the passage has no words so callers never divide by zero.
  static int accuracyPercent({required int totalWords, required int miscues}) {
    if (totalWords <= 0) return 0;
    final clampedMiscues = miscues.clamp(0, totalWords);
    return (((totalWords - clampedMiscues) / totalWords) * 100).round();
  }

  /// Phil-IRI word-reading band: 97–100 Independent, 90–96 Instructional,
  /// 89 and below Frustration.
  static String fromAccuracy(int percent) {
    if (percent >= 97) return independent;
    if (percent >= 90) return instructional;
    return frustration;
  }

  /// Combines word reading and comprehension into the overall reading profile
  /// using the Phil-IRI matrix. Unknown comprehension values fall back to the
  /// word-reading level.
  static String overall(String wordReading, String comprehension) {
    const matrix = {
      independent: {
        independent: independent,
        instructional: instructional,
        frustration: instructional,
      },
      instructional: {
        independent: instructional,
        instructional: instructional,
        frustration: frustration,
      },
      frustration: {
        independent: instructional,
        instructional: frustration,
        frustration: frustration,
      },
    };
    return matrix[wordReading]?[comprehension] ?? wordReading;
  }

  /// Reads an int that may have been stored as int, double or string.
  static int parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }
}
