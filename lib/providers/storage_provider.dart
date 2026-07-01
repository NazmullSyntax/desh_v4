import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../data/repositories/firebase_storage_repository.dart';
import '../data/repositories/mock_storage_repository.dart';
import '../domain/repositories/storage_repository.dart';

/// Provides the active [StorageRepository] implementation, following the
/// same on/off pattern as [authRepositoryProvider] in auth_provider.dart.
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  if (AppConfig.useFirebase) {
    return FirebaseStorageRepository();
  }
  return MockStorageRepository();
});
