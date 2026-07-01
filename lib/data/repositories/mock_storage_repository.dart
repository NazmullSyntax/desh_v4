import 'dart:io';
import '../../domain/repositories/storage_repository.dart';

/// Mock implementation of [StorageRepository] used before Firebase is
/// configured. Instead of actually uploading anywhere, it just returns the
/// local file's own path as a `file://` URL — [AppNetworkImage] doesn't
/// render `file://` paths today, so the UI layer treats this the same way
/// it treats a bundled asset path that doesn't resolve (graceful
/// placeholder icon). This keeps "Edit Profile" fully clickable and
/// functional in demos without a backend, while making it obvious in code
/// review which storage backend is active.
class MockStorageRepository implements StorageRepository {
  @override
  Future<String> uploadFile({
    required String localFilePath,
    required String folder,
    required String fileName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Uri.file(localFilePath).toString();
  }

  @override
  Future<void> deleteFile(String downloadUrl) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}

/// Returns true if the given path/URL looks like a local device file
/// rather than a real network URL — used so the UI can still render a
/// freshly-picked photo immediately, even in mock mode, by reading bytes
/// straight off disk instead of going through [AppNetworkImage]'s network
/// path.
bool isLocalFilePath(String path) {
  return path.startsWith('file://') || (!path.startsWith('http://') && !path.startsWith('https://') && File(path).existsSync());
}
