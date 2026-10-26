/// Makes a database value safe to use inside a file name.
///
/// Section and school-year names come from Firestore; a value such as
/// `../../x` or one containing `/` must not be able to escape the export
/// folder or create sub-directories.
String safeFileName(Object? value) {
  final cleaned = (value ?? '')
      .toString()
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
      .replaceAll(RegExp(r'\.{2,}'), '_')
      .trim();
  if (cleaned.isEmpty) return 'export';
  return cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
}
