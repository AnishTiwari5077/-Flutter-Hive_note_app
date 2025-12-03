import 'package:flutter/material.dart';
import 'package:hive_database/services/box.dart';
import 'package:hive_database/widgets/note_delete_confirmation.dart';
import 'package:hive_database/widgets/note_details_dialog.dart';
import 'package:hive_flutter/adapters.dart';
import '../models/note_model.dart';

import '../utils/constants.dart';
import '../widgets/note_dialog.dart';
import '../widgets/note_card.dart';
import '../widgets/empty_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showAddDialog({NoteModel? note}) {
    showDialog(
      context: context,
      builder: (context) => NoteDialog(note: note),
    );
  }

  void _showDeleteDialog(NoteModel note) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        onConfirm: () {
          note.delete();
          _showSnackBar(AppStrings.noteDeleted);
        },
      ),
    );
  }

  void _showNoteDetails(NoteModel note) {
    showDialog(
      context: context,
      builder: (context) => NoteDetailDialog(
        note: note,
        onEdit: () => _showAddDialog(note: note),
        onDelete: () => _showDeleteDialog(note),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: true,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'clear') {
                _showClearAllDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Notes'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<NoteModel>>(
        valueListenable: Boxes.getNotes().listenable(),
        builder: (context, box, _) {
          final notes = box.values.toList().reversed.toList();

          if (notes.isEmpty) {
            return const EmptyState();
          }

          return ListView.builder(
            padding: AppConstants.screenPadding,
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteCard(
                note: note,
                onTap: () => _showNoteDetails(note),
                onEdit: () => _showAddDialog(note: note),
                onDelete: () => _showDeleteDialog(note),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addNote),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notes'),
        content: const Text(
          'Are you sure you want to delete all notes? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              await Boxes.clearAll();
              if (mounted) {
                Navigator.pop(context);
                _showSnackBar('All notes deleted');
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteColor),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
