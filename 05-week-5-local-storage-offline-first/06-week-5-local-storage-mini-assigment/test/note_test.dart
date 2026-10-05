import 'package:flutter_test/flutter_test.dart';
import 'package:week5_mini_assignment/models/note.dart';

void main() {
  group('Note model', () {
    final updated = DateTime(2026, 5, 1, 10, 30);
    final created = DateTime(2026, 5, 1, 9, 0);

    test('round-trips through toMap/fromMap (serialization)', () {
      final note = Note(
        id: 7,
        title: 'Belanja',
        content: 'Beli kopi',
        createdAt: created,
        updatedAt: updated,
        isDirty: true,
        isDeleted: false,
      );

      final restored = Note.fromMap(note.toMap());

      expect(restored, equals(note));
      expect(restored.id, 7);
      expect(restored.title, 'Belanja');
      expect(restored.content, 'Beli kopi');
      expect(restored.updatedAt, updated);
      expect(restored.createdAt, created);
      expect(restored.isDirty, isTrue);
      expect(restored.isDeleted, isFalse);
    });

    test('stores dirty/deleted flags as SQLite-friendly ints', () {
      final map = Note(
        title: 'x',
        content: 'y',
        updatedAt: updated,
        isDirty: true,
        isDeleted: true,
      ).toMap();

      expect(map['is_dirty'], 1);
      expect(map['is_deleted'], 1);
      expect(map['updated_at'], updated.millisecondsSinceEpoch);
    });

    test('copyWith marks a note clean without mutating the original', () {
      final dirty = Note(title: 'a', content: 'b', updatedAt: updated);
      final clean = dirty.copyWith(isDirty: false);

      expect(dirty.isDirty, isTrue);
      expect(clean.isDirty, isFalse);
      expect(clean.title, 'a');
    });

    test('new notes default to dirty so sync picks them up', () {
      final note = Note(title: 'a', content: 'b', updatedAt: updated);
      expect(note.isDirty, isTrue);
      expect(note.isDeleted, isFalse);
    });
  });
}
