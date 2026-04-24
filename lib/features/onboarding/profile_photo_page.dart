import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/image_upload_service.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_ui.dart';

class ProfilePhotoPage extends ConsumerStatefulWidget {
  const ProfilePhotoPage({required this.onComplete, super.key});

  final void Function(List<String> urls) onComplete;

  @override
  ConsumerState<ProfilePhotoPage> createState() => _ProfilePhotoPageState();
}

class _ProfilePhotoPageState extends ConsumerState<ProfilePhotoPage> {
  final _photoUrls = <String>[];
  bool _uploading = false;

  Future<void> _pickFromGallery() async {
    final service = ref.read(imageUploadServiceProvider);
    final files = await service.pickImages(limit: 5 - _photoUrls.length);
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    for (final file in files) {
      final url = await service.uploadProfilePhoto(file);
      if (url != null) _photoUrls.add(url);
    }
    setState(() => _uploading = false);
  }

  Future<void> _pickFromCamera() async {
    final service = ref.read(imageUploadServiceProvider);
    final file = await service.pickFromCamera();
    if (file == null) return;
    setState(() => _uploading = true);
    final url = await service.uploadProfilePhoto(file);
    if (url != null) _photoUrls.add(url);
    setState(() => _uploading = false);
  }

  void _removePhoto(int index) {
    setState(() => _photoUrls.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              locale.profilePhotoTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              locale.profilePhotoSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (_photoUrls.length < 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: InfoPill(
                  icon: Icons.lightbulb_outline,
                  label: locale.profilePhotoNudge,
                  highlighted: true,
                ),
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                ..._photoUrls.asMap().entries.map((entry) {
                  return _PhotoTile(
                    imageUrl: entry.value,
                    onRemove: () => _removePhoto(entry.key),
                  );
                }),
                if (_photoUrls.length < 5)
                  _AddPhotoTile(
                    onGallery: _pickFromGallery,
                    onCamera: _pickFromCamera,
                  ),
              ],
            ),
            const SizedBox(height: 32),
            if (_uploading)
              const Center(child: CircularProgressIndicator())
            else
              GradientActionButton(
                key: const Key('onboarding_photo_next'),
                label: locale.onboardingNext,
                onPressed: _photoUrls.isNotEmpty
                    ? () => widget.onComplete(_photoUrls)
                    : null,
                icon: Icons.arrow_forward_rounded,
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.imageUrl, required this.onRemove});

  final String imageUrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            imageUrl,
            width: 130,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 130,
              height: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        Positioned(
          right: -6,
          top: -6,
          child: Material(
            color: Theme.of(context).colorScheme.error,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onGallery, required this.onCamera});

  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onGallery,
        onLongPress: onCamera,
        child: SizedBox(
          width: 130,
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 36,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).addPhotoCta,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
