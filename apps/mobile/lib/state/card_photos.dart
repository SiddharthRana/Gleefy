import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Photos people add to their own Dream Team cards. Picked from the phone's gallery, copied into
/// the app's private folder and never uploaded, shared or put in share links.

/// The folder photos are kept in (set at startup; null in tests until overridden).
final cardPhotosDirProvider = Provider<String?>((ref) => null);

/// Picks a photo from the gallery and saves a small copy in [dir]. Returns the file's name, or
/// null if the person cancelled.
abstract interface class PhotoPicker {
  Future<String?> pick(String dir);
}

class GalleryPhotoPicker implements PhotoPicker {
  GalleryPhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  final _random = Random();

  @override
  Future<String?> pick(String dir) async {
    // Android uses the system photo picker, so no storage permission is needed.
    final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600, imageQuality: 82);
    if (file == null) return null;
    await Directory(dir).create(recursive: true);
    final name = 'card-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(1 << 20)}.jpg';
    await File('$dir/$name').writeAsBytes(await file.readAsBytes());
    return name;
  }
}

final photoPickerProvider = Provider<PhotoPicker>((ref) => GalleryPhotoPicker());

/// Full path of a saved photo, or null if it's gone (e.g. the app's data was cleared).
String? cardPhotoPath(String? dir, String? fileName) {
  if (dir == null || fileName == null) return null;
  final path = '$dir/$fileName';
  return File(path).existsSync() ? path : null;
}

/// Deletes photo files nothing uses any more.
void deleteCardPhotos(String? dir, Iterable<String> fileNames) {
  if (dir == null) return;
  for (final name in fileNames) {
    final f = File('$dir/$name');
    if (f.existsSync()) f.deleteSync();
  }
}
