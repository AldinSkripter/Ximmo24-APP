import 'package:file_picker/file_picker.dart';

/// Centralized wrapper around [FilePicker] so file-picking config
/// (type, allowed extensions) stays consistent across the app.
class AppFilePicker {
  const AppFilePicker._();

  /// Pick a single file. Returns null if the user cancels the picker.
  static Future<PlatformFile?> pickFile({
    FileType type = FileType.custom,
    List<String>? allowedExtensions,
  }) {
    return FilePicker.pickFile(
      type: type,
      allowedExtensions: allowedExtensions,
    );
  }

  /// Pick multiple files. Returns null if the user cancels the picker.
  static Future<List<PlatformFile>?> pickFiles({
    FileType type = FileType.custom,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
    );
    return result?.files;
  }
}
