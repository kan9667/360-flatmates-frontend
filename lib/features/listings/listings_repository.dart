import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class ListingCreateRequest {
  const ListingCreateRequest({
    required this.title,
    required this.description,
    required this.city,
    required this.locality,
    required this.subLocality,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.maintenanceCharges,
    required this.areaSqft,
    required this.bedrooms,
    required this.bathrooms,
    required this.features,
    required this.mainImageUrl,
    required this.availableFrom,
    required this.genderPreference,
    required this.sharingType,
  });

  final String title;
  final String? description;
  final String? city;
  final String? locality;
  final String? subLocality;
  final double monthlyRent;
  final double? securityDeposit;
  final double? maintenanceCharges;
  final double? areaSqft;
  final int? bedrooms;
  final int? bathrooms;
  final List<String> features;
  final String? mainImageUrl;
  final DateTime? availableFrom;
  final String genderPreference;
  final String sharingType;

  Map<String, dynamic> toJson() {
    final fullAddress = [
      if (subLocality != null && subLocality!.trim().isNotEmpty)
        subLocality!.trim(),
      if (locality != null && locality!.trim().isNotEmpty) locality!.trim(),
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
    ].join(', ');

    return {
      'title': title,
      'description': description,
      'property_type': 'flatmate',
      'purpose': 'rent',
      'base_price': monthlyRent,
      'monthly_rent': monthlyRent,
      'city': city,
      'locality': locality,
      'sub_locality': subLocality,
      'full_address': fullAddress.isEmpty ? null : fullAddress,
      'area_sqft': areaSqft,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'security_deposit': securityDeposit,
      'maintenance_charges': maintenanceCharges,
      'features': features.isEmpty ? null : features,
      'main_image_url': mainImageUrl,
      'available_from': availableFrom?.toUtc().toIso8601String(),
      'listing_preferences': {
        'gender_preference': genderPreference,
        'sharing_type': sharingType,
      },
    };
  }
}

class ListingsRepository {
  const ListingsRepository(this._ref);

  final Ref _ref;

  Future<void> createListing(ListingCreateRequest request) async {
    await _ref
        .watch(apiClientProvider)
        .post('/properties', data: request.toJson());
  }
}

final listingsRepositoryProvider = Provider<ListingsRepository>(
  (ref) => ListingsRepository(ref),
);
