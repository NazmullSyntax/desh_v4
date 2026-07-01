/// Domain-layer contract for binary file storage (profile photos, travel
/// diary images, review photos, etc). Mirrors the [AuthRepository] pattern:
/// screens only ever talk to this interface, never to Firebase Storage
/// directly, so the backend can be swapped without touching UI code.
abstract class StorageRepository {
  /// Uploads a file from a local device path and returns a public download
  /// URL. [folder] groups uploads logically in storage (e.g. "profile_photos",
  /// "diary_photos", "review_photos").
  Future<String> uploadFile({
    required String localFilePath,
    required String folder,
    required String fileName,
  });

  /// Deletes a previously uploaded file given its download URL.
  Future<void> deleteFile(String downloadUrl);
}
