import 'package:hive/hive.dart';
import '../models/note_model.dart';

class Boxes {
  static const String noteBoxName = 'notes';

  static Box<NoteModel> getNotes() {
    if (!Hive.isBoxOpen(noteBoxName)) {
      throw Exception('Notes box is not open. Call initialize() first.');
    }
    return Hive.box<NoteModel>(noteBoxName);
  }

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(noteBoxName)) {
      await Hive.openBox<NoteModel>(noteBoxName);
    }
  }

  static Future<void> close() async {
    if (Hive.isBoxOpen(noteBoxName)) {
      await Hive.box<NoteModel>(noteBoxName).close();
    }
  }

  static Future<void> clearAll() async {
    await getNotes().clear();
  }
}
