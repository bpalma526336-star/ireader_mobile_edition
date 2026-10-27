import 'package:flutter_test/flutter_test.dart';
import 'package:ireader_mobile_edition/core/reading_level.dart';
import 'package:ireader_mobile_edition/core/safe_file_name.dart';

void main() {
  group('ReadingLevel.accuracyPercent', () {
    test('computes rounded accuracy', () {
      expect(ReadingLevel.accuracyPercent(totalWords: 100, miscues: 3), 97);
    });
    test('zero words does not divide by zero', () {
      expect(ReadingLevel.accuracyPercent(totalWords: 0, miscues: 5), 0);
    });
    test('miscues above total clamp to 0%', () {
      expect(ReadingLevel.accuracyPercent(totalWords: 10, miscues: 50), 0);
    });
  });

  test('fromAccuracy bands', () {
    expect(ReadingLevel.fromAccuracy(97), 'Independent');
    expect(ReadingLevel.fromAccuracy(90), 'Instructional');
    expect(ReadingLevel.fromAccuracy(89), 'Frustration');
  });

  test('overall covers every word/comprehension pair', () {
    const levels = ['Independent', 'Instructional', 'Frustration'];
    for (final w in levels) {
      for (final c in levels) {
        expect(levels, contains(ReadingLevel.overall(w, c)));
      }
    }
    expect(ReadingLevel.overall('Independent', 'Frustration'), 'Instructional');
    expect(ReadingLevel.overall('Frustration', 'Independent'), 'Instructional');
  });

  test('parseInt handles stored strings and doubles', () {
    expect(ReadingLevel.parseInt('120'), 120);
    expect(ReadingLevel.parseInt(99.6), 100);
    expect(ReadingLevel.parseInt(null), 0);
  });

  test('safeFileName blocks path traversal', () {
    expect(safeFileName('../../etc/passwd'), isNot(contains('/')));
    expect(safeFileName('../x'), isNot(contains('..')));
    expect(safeFileName(''), 'export');
  });
}
