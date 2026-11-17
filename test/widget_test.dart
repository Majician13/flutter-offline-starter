// Unit tests for the search rule in lib/db_helper.dart.
//
// matchesWordStart is a pure function — no database needed — so these
// run fast under `flutter test` and pin down the one rule the whole
// app's search depends on: a keyword may start a word, it may not
// hide inside one.
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_starter/db_helper.dart';

void main() {
  group('matchesWordStart', () {
    test('empty keyword matches everything', () {
      expect(matchesWordStart('anything at all', ''), isTrue);
      expect(matchesWordStart(null, ''), isTrue);
    });

    test('null text never matches a keyword', () {
      expect(matchesWordStart(null, 'drill'), isFalse);
    });

    test('keyword starts a word', () {
      expect(matchesWordStart('Cordless drill', 'drill'), isTrue);
      expect(matchesWordStart('Cordless drill', 'cord'), isTrue);
    });

    test('keyword may continue a word', () {
      expect(matchesWordStart('drilling a hole', 'drill'), isTrue);
    });

    test('keyword may not hide inside a word', () {
      expect(matchesWordStart('Cordless drill', 'ill'), isFalse);
      expect(matchesWordStart('fundamental', 'mental'), isFalse);
    });

    test('matching is case-insensitive', () {
      expect(matchesWordStart('Cast Iron Skillet', 'skillet'), isTrue);
      expect(matchesWordStart('Cast Iron Skillet', 'SKILLET'), isTrue);
    });

    test('leading and trailing spaces are ignored', () {
      expect(matchesWordStart('Garden hose', '  hose  '), isTrue);
    });
  });
}
