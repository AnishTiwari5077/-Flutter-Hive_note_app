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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Stores {note, originalIndex} for undo support
  final List<Map<String, dynamic>> _deletedNotes = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NoteModel> _filterNotes(List<NoteModel> notes) {
    if (_searchQuery.isEmpty) return notes;
    final query = _searchQuery.toLowerCase();
    return notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.description.toLowerCase().contains(query);
    }).toList();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

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
          _deleteNote(note);
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

  /// Core delete — saves position, removes from Hive, shows undo SnackBar
  void _deleteNote(NoteModel note) {
    final box = Boxes.getNotes();
    final allNotes = box.values.toList();

    // Find original index in the box (not reversed list)
    final originalIndex = allNotes.indexOf(note);

    // Snapshot note data before deleting
    final deletedTitle = note.title;
    final deletedDescription = note.description;
    final deletedCreatedAt = note.createdAt;
    final deletedUpdatedAt = note.updatedAt;

    note.delete();

    _deletedNotes.add({
      'title': deletedTitle,
      'description': deletedDescription,
      'createdAt': deletedCreatedAt,
      'updatedAt': deletedUpdatedAt,
      'index': originalIndex,
    });

    _showUndoSnackBar(deletedTitle);
  }

  void _showUndoSnackBar(String title) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$title" deleted'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Undo', onPressed: _undoDelete),
      ),
    );
  }

  /// Restores the most recently deleted note at its exact original position
  Future<void> _undoDelete() async {
    if (_deletedNotes.isEmpty) return;

    final deleted = _deletedNotes.removeLast();
    final box = Boxes.getNotes();
    final targetIndex = (deleted['index'] as int).clamp(0, box.length);

    // Snapshot all current notes as plain maps BEFORE touching the box
    final snapshot = box.values
        .map(
          (n) => {
            'title': n.title,
            'description': n.description,
            'createdAt': n.createdAt,
            'updatedAt': n.updatedAt,
          },
        )
        .toList();

    // Build the full new list in memory first
    final rebuilt = <NoteModel>[];
    for (int i = 0; i <= snapshot.length; i++) {
      if (i == targetIndex) {
        rebuilt.add(
          NoteModel(
            title: deleted['title'] as String,
            description: deleted['description'] as String,
            createdAt: deleted['createdAt'] as DateTime,
            updatedAt: deleted['updatedAt'] as DateTime?,
          ),
        );
      }
      if (i < snapshot.length) {
        final e = snapshot[i];
        rebuilt.add(
          NoteModel(
            title: e['title'] as String,
            description: e['description'] as String,
            createdAt: e['createdAt'] as DateTime,
            updatedAt: e['updatedAt'] as DateTime?,
          ),
        );
      }
    }

    // Now touch the box — await both operations
    await box.clear();
    await box.addAll(rebuilt);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${deleted['title']}" restored'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
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
        centerTitle: true,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text(AppConstants.appName),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel search',
              onPressed: _stopSearch,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search notes',
              onPressed: _startSearch,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'clear') _showClearAllDialog();
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
        ],
      ),
      body: Column(
        children: [
          Divider(height: 1, thickness: 1),
          Expanded(
            child: ValueListenableBuilder<Box<NoteModel>>(
              valueListenable: Boxes.getNotes().listenable(),
              builder: (context, box, _) {
                final allNotes = box.values.toList().reversed.toList();
                final notes = _filterNotes(allNotes);

                if (allNotes.isEmpty) return const EmptyState();

                if (notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: AppColors.emptyStateColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notes match "$_searchQuery"',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.emptyStateColor),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: AppConstants.screenPadding,
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Dismissible(
                      // Key must be unique and stable per note
                      key: ValueKey(note.key),
                      direction: DismissDirection.endToStart, // swipe left only
                      onDismissed: (_) => _deleteNote(note),
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadius,
                          ),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      child: NoteCard(
                        note: note,
                        onTap: () => _showNoteDetails(note),
                        onEdit: () => _showAddDialog(note: note),
                        onDelete: () => _showDeleteDialog(note),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isSearching
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddDialog(),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.addNote),
            ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear All Notes'),
        content: const Text(
          'Are you sure you want to delete all notes? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              await Boxes.clearAll();
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              _showSnackBar('All notes deleted');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteColor),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
