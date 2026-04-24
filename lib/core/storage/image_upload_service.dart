import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  const ImageUploadService();

  Future<List<File>> pickImages({int limit = 10}) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80);
    if (images.isEmpty) return [];
    return images.take(limit).map((x) => File(x.path)).toList();
  }

  Future<File?> pickFromCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo == null) return null;
    return File(photo.path);
  }

  Future<File?> pickVideo({Duration maxDuration = const Duration(seconds: 30)}) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxDuration,
    );
    if (video == null) return null;
    return File(video.path);
  }

  Future<VideoValidationResult> validateVideo(File file) async {
    final size = await file.length();
    if (size > 50 * 1024 * 1024) {
      return VideoValidationResult(tooLarge: true, tooLong: false);
    }
    return const VideoValidationResult(tooLarge: false, tooLong: false);
  }

  Future<String?> uploadProfilePhoto(File file) async {
    return _upload(file, 'profile-photos');
  }

  Future<String?> uploadListingPhoto(File file) async {
    return _upload(file, 'listing-photos');
  }

  Future<String?> uploadChatPhoto(File file) async {
    return _upload(file, 'chat-photos');
  }

  Future<String?> uploadVideoTour(File file) async {
    return _upload(file, 'listing-videos');
  }

  Future<String?> _upload(File file, String bucket) async {
    final supabase = Supabase.instance.client;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    try {
      await supabase.storage.from(bucket).upload(fileName, file);
      return supabase.storage.from(bucket).getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }
}

class VideoValidationResult {
  const VideoValidationResult({required this.tooLarge, required this.tooLong});
  final bool tooLarge;
  final bool tooLong;
  bool get isValid => !tooLarge && !tooLong;
}

final imageUploadServiceProvider = Provider<ImageUploadService>(
  (ref) => const ImageUploadService(),
);
