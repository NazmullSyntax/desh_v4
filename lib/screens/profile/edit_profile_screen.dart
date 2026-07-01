import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/primary_button.dart';

/// Lets the signed-in user change their display name and profile photo.
///
/// Photo picking works via [image_picker] (camera or gallery). The actual
/// upload goes through [AuthController.updateProfile], which routes the
/// file through [StorageRepository] — Firebase Storage once configured,
/// or a local mock today (see lib/data/repositories/mock_storage_repository.dart).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  String? _pickedPhotoPath;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.isGuest == true ? '' : (user?.name ?? ''));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 85);
      if (picked != null) {
        setState(() => _pickedPhotoPath = picked.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}: $e')),
      );
    }
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (user.isGuest && _nameController.text.trim().isEmpty && _pickedPhotoPath == null) {
      Navigator.of(context).pop();
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).updateProfile(
          name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
          localPhotoPath: _pickedPhotoPath,
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      Navigator.of(context).pop();
    } else {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Could not update profile.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                      ),
                      child: ClipOval(
                        child: _pickedPhotoPath != null
                            ? AppNetworkImage(url: _pickedPhotoPath!, width: 110, height: 110)
                            : (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                                ? AppNetworkImage(url: user.photoUrl!, width: 110, height: 110)
                                : Container(
                                    color: AppColors.primary.withOpacity(0.12),
                                    alignment: Alignment.center,
                                    child: Text(
                                      (user?.displayName.isNotEmpty ?? false) ? user!.displayName[0].toUpperCase() : 'T',
                                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: AppColors.primary),
                                    ),
                                  ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              if (user?.isGuest ?? false)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.accentDark, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You\'re browsing as a guest. Create an account to keep your name and photo saved.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              AppTextField(
                label: 'Display Name',
                controller: _nameController,
                hint: 'Your name',
                prefixIcon: Icons.person_outline,
              ),
              if (user?.email != null) ...[
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Email', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(user!.email!, style: Theme.of(context).textTheme.bodyMedium)),
                      Text('Cannot be changed here', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              PrimaryButton(label: 'Save Changes', onPressed: _save, isLoading: isLoading),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
