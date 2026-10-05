/// Domain model for a single note.
///
/// The [isDirty] flag implements the offline-first "write" strategy:
/// every local create/update/delete marks the row dirty so a later
/// [NoteRepository.syncNotes] call knows exactly what still has to be
/// pushed to the remote backend.
class Note {
  const Note({
    this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.createdAt,
    this.isDirty = true,
    this.isDeleted = false,
  });

  /// Local (autoincrement) primary key. `null` means not yet persisted.
  final int? id;
  final String title;
  final String content;
  final DateTime updatedAt;
  final DateTime? createdAt;

  /// `true` when the local copy has changes that have not been synced.
  final bool isDirty;

  /// Soft-delete marker. Keeping the row (instead of hard deleting it) lets
  /// the sync step report the deletion to the backend before purging locally.
  final bool isDeleted;

  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? updatedAt,
    DateTime? createdAt,
    bool? isDirty,
    bool? isDeleted,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      isDirty: isDirty ?? this.isDirty,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'created_at': (createdAt ?? updatedAt).millisecondsSinceEpoch,
      'is_dirty': isDirty ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Note.fromMap(Map<String, Object?> map) {
    return Note(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updated_at'] as int?) ?? 0,
      ),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isDirty: (map['is_dirty'] as int? ?? 0) == 1,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, dirty: $isDirty, deleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    return other is Note &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.updatedAt == updatedAt &&
        other.createdAt == createdAt &&
        other.isDirty == isDirty &&
        other.isDeleted == isDeleted;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        content,
        updatedAt,
        createdAt,
        isDirty,
        isDeleted,
      );
}
