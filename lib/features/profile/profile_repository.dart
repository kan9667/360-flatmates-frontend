import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../bootstrap/bootstrap_controller.dart';

class ProfileRepository {
  const ProfileRepository(this._ref);

  final Ref _ref;

  Future<FlatmatesProfileModel> updateProfile({
    required Map<String, dynamic> payload,
  }) async {
    final response = await _ref
        .watch(apiClientProvider)
        .put('/flatmates/profile', data: payload);
    return FlatmatesProfileModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<FlatmatesProfileModel> fetchProfile() async {
    final response = await _ref
        .watch(apiClientProvider)
        .get('/flatmates/profile');
    return FlatmatesProfileModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref),
);
