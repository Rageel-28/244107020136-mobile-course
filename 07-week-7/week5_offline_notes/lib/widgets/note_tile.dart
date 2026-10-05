import 'package:flutter/material.dart';
 
import '../data/local/note.dart';
 
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });
 
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;
 
  @override
  Widget build(BuildContext context) {
    return ListTile(
      isThreeLine: note.dirty,
      leading: Icon(
        note.dirty ? Icons.cloud_off : Icons.cloud_done,
        color: note.dirty ? Colors.orange : Colors.green,
      ),
      title: Text(note.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            note.body.isEmpty ? '(tanpa isi)' : note.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (note.dirty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Chip(
                label: Text('Belum tersinkron'),
                labelStyle: TextStyle(fontSize: 11),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
      onTap: onTap,
      trailing: IconButton(
        tooltip: 'Hapus',
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}
