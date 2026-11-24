import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class ManagedPickedFile {
  const ManagedPickedFile({
    required this.bytes,
    required this.fileName,
    required this.isImage,
  });

  final Uint8List bytes;
  final String fileName;
  final bool isImage;
}

typedef ManagedFilePicker =
    Future<ManagedPickedFile?> Function({required bool imagesOnly});

Future<ManagedPickedFile?> pickManagedFile({required bool imagesOnly}) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: imagesOnly
        ? const ['jpg', 'jpeg', 'png', 'webp']
        : const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    allowMultiple: false,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null) return null;
  const imageExtensions = {'jpg', 'jpeg', 'png', 'webp'};
  final extension = (file.extension ?? '').toLowerCase();
  return ManagedPickedFile(
    bytes: Uint8List.fromList(bytes),
    fileName: file.name,
    isImage: imageExtensions.contains(extension),
  );
}
