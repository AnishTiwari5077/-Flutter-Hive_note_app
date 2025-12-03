import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'My Notes';
  static const double cardElevation = 2.0;
  static const double borderRadius = 12.0;

  static const EdgeInsets cardPadding = EdgeInsets.all(12);
  static const EdgeInsets screenPadding = EdgeInsets.all(8);
  static const EdgeInsets dialogPadding = EdgeInsets.all(24);
}

class AppColors {
  static const Color editColor = Colors.blue;
  static const Color deleteColor = Colors.red;
  static const Color emptyStateColor = Colors.grey;
}

class AppStrings {
  static const String addNote = 'Add Note';
  static const String editNote = 'Edit Note';
  static const String deleteNote = 'Delete Note';
  static const String deleteConfirmation =
      'Are you sure you want to delete this note?';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String close = 'Close';

  static const String titleHint = 'Enter note title';
  static const String descriptionHint = 'Enter note description';
  static const String titleLabel = 'Title';
  static const String descriptionLabel = 'Description';

  static const String titleRequired = 'Please enter a title';
  static const String descriptionRequired = 'Please enter a description';

  static const String noteAdded = 'Note added successfully';
  static const String noteUpdated = 'Note updated successfully';
  static const String noteDeleted = 'Note deleted successfully';

  static const String emptyStateTitle = 'No notes yet';
  static const String emptyStateSubtitle =
      'Tap the + button to create your first note';
}
