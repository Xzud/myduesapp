import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feature-first clean architecture boundaries', () {
    test('should use application domain infrastructure layers for dues', () {
      expect(Directory('lib/features/dues/application').existsSync(), isTrue);
      expect(
        Directory('lib/features/dues/domain/repositories').existsSync(),
        isTrue,
      );
      expect(
        Directory('lib/features/dues/infrastructure').existsSync(),
        isTrue,
      );
      expect(Directory('lib/features/dues/data').existsSync(), isFalse);
      expect(
        Directory('lib/features/dues/domain/usecases').existsSync(),
        isFalse,
      );
    });

    test('should keep presentation independent from infrastructure', () {
      final presentationFiles = Directory('lib/features/dues/presentation')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in presentationFiles) {
        final content = file.readAsStringSync();
        expect(
          content,
          isNot(contains('features/dues/infrastructure')),
          reason: '${file.path} must not import infrastructure',
        );
        expect(
          content,
          isNot(contains('features/dues/data')),
          reason: '${file.path} must not import legacy data layer',
        );
      }
    });

    test(
      'should keep application and domain independent from Flutter and IO',
      () {
        final guardedDirs = [
          Directory('lib/features/dues/application'),
          Directory('lib/features/dues/domain'),
        ];

        for (final dir in guardedDirs) {
          final files = dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'));

          for (final file in files) {
            final content = file.readAsStringSync();
            expect(
              content,
              isNot(contains('package:flutter')),
              reason: '${file.path} must not depend on Flutter',
            );
            expect(
              content,
              isNot(contains('features/dues/infrastructure')),
              reason: '${file.path} must not depend on infrastructure',
            );
            expect(
              content,
              isNot(contains('features/dues/data')),
              reason: '${file.path} must not depend on legacy data layer',
            );
            expect(
              content,
              isNot(contains('package:sqflite')),
              reason: '${file.path} must not depend on SQLite',
            );
          }
        }
      },
    );
  });
}
