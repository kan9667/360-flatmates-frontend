import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/storage/image_upload_service.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/flatmates_ui.dart';
import 'listings_repository.dart';

class CreateListingPage extends ConsumerStatefulWidget {
  const CreateListingPage({super.key});

  @override
  ConsumerState<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends ConsumerState<CreateListingPage> {
  int _step = 0;
  bool _submitting = false;

  // Step 1 - Location
  final _societyController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _localityController = TextEditingController();

  // Step 2 - Society
  String _societyType = 'gated';
  final _societyAmenities = <String>{};
  final _societyVibeTags = <String>{};

  static const _societyAmenityOptions = [
    ('pool', Icons.pool_outlined),
    ('gym', Icons.fitness_center_outlined),
    ('clubhouse', Icons.celebration_outlined),
    ('sports', Icons.sports_soccer_outlined),
    ('parking', Icons.local_parking_outlined),
    ('power_backup', Icons.power_outlined),
    ('water_backup', Icons.water_drop_outlined),
    ('security', Icons.security_outlined),
    ('lift', Icons.elevator_outlined),
    ('cctv', Icons.videocam_outlined),
    ('visitor_entry', Icons.badge_outlined),
    ('garden', Icons.park_outlined),
  ];

  static const _societyVibeOptions = [
    ('bachelor_friendly', Icons.group_outlined),
    ('quiet', Icons.nightlight_outlined),
    ('active_community', Icons.celebration_outlined),
    ('family_dominant', Icons.family_restroom_outlined),
    ('pet_friendly', Icons.pets_outlined),
    ('visitor_friendly', Icons.waving_hand_outlined),
  ];

  // Step 3 - Room
  String _roomType = 'private_room';
  final _roomFurnishing = <String>{};
  final _roomFeatures = <String>{};
  final _roomPhotoUrls = <String>[];
  String? _videoTourUrl;
  bool _videoUploading = false;
  static const _furnishingOptions = [
    ('bed', Icons.bed_outlined),
    ('wardrobe', Icons.checkroom_outlined),
    ('ac', Icons.ac_unit_outlined),
    ('geyser', Icons.hot_tub_outlined),
    ('study_table', Icons.desk_outlined),
    ('curtains', Icons.blinds_outlined),
  ];

  static const _roomFeatureOptions = [
    ('attached_bathroom', Icons.bathtub_outlined),
    ('private_balcony', Icons.balcony_outlined),
    ('window_sunlight', Icons.wb_sunny_outlined),
    ('storage_space', Icons.inventory_2_outlined),
  ];

  // Step 4 - Flat
  String _flatConfig = '2BHK';
  final _floorController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  final _flatAmenities = <String>{};

  static const _flatAmenityOptions = [
    ('wifi', Icons.wifi_outlined),
    ('washing_machine', Icons.local_laundry_service_outlined),
    ('refrigerator', Icons.kitchen_outlined),
    ('microwave', Icons.microwave_outlined),
    ('tv', Icons.tv_outlined),
    ('dining_table', Icons.table_restaurant_outlined),
    ('sofa', Icons.weekend_outlined),
    ('kitchen_equipped', Icons.soup_kitchen_outlined),
  ];

  // Step 5 - Costs
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _maintenanceController = TextEditingController();
  String _electricityIncluded = 'separate';
  final _electricityEstController = TextEditingController();
  final _cookCostController = TextEditingController();
  final _maidCostController = TextEditingController();
  final _setupCostController = TextEditingController();

  // Step 6 - About & Preferred Flatmate
  final _typicalDayController = TextEditingController();
  String _genderPreference = 'any';
  double _ageMin = 18;
  double _ageMax = 40;
  final _nonNegotiables = <String>{};
  DateTime? _availableFrom;

  static const _nonNegotiableOptions = [
    'food_veg_only', 'no_smoking', 'no_drinking',
    'no_overnight_guests', 'no_pets', 'no_parties', 'min_tidy',
  ];

  static const _stepEmojis = ['📍', '🏘️', '🌳', '🏠', '💰', '🧬', '✅'];

  @override
  void dispose() {
    for (final c in [
      _societyController, _addressController, _cityController, _localityController,
      _floorController, _totalFloorsController, _rentController, _depositController,
      _maintenanceController, _electricityEstController, _cookCostController,
      _maidCostController, _setupCostController, _typicalDayController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _canProceed() {
    return switch (_step) {
      0 => _societyController.text.trim().isNotEmpty && _cityController.text.trim().isNotEmpty && _localityController.text.trim().isNotEmpty,
      1 => true,
      2 => _roomPhotoUrls.length >= 2,
      3 => _rentController.text.trim().isNotEmpty,
      4 => double.tryParse(_rentController.text.trim()) != null,
      5 => true,
      6 => true,
      _ => false,
    };
  }

  double get _totalMonthlyOutflow {
    double rent = double.tryParse(_rentController.text.trim()) ?? 0;
    double maintenance = double.tryParse(_maintenanceController.text.trim()) ?? 0;
    double electricity = _electricityIncluded == 'separate'
        ? (double.tryParse(_electricityEstController.text.trim()) ?? 0)
        : 0;
    double cook = double.tryParse(_cookCostController.text.trim()) ?? 0;
    double maid = double.tryParse(_maidCostController.text.trim()) ?? 0;
    return rent + maintenance + electricity + cook + maid;
  }

  Future<void> _pickRoomPhotos() async {
    final service = ref.read(imageUploadServiceProvider);
    final files = await service.pickImages(limit: 10 - _roomPhotoUrls.length);
    if (files.isEmpty) return;
    for (final file in files) {
      final url = await service.uploadListingPhoto(file);
      if (url != null) setState(() => _roomPhotoUrls.add(url));
    }
  }

  Future<void> _submit() async {
    final locale = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      var request = ListingCreateRequest(
        title: '$_flatConfig in ${_societyController.text.trim()}',
        description: _typicalDayController.text.trim().isEmpty
            ? null
            : _typicalDayController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        locality: _localityController.text.trim().isEmpty ? null : _localityController.text.trim(),
        subLocality: _societyController.text.trim().isEmpty ? null : _societyController.text.trim(),
        monthlyRent: double.parse(_rentController.text.trim()),
        securityDeposit: double.tryParse(_depositController.text.trim()),
        maintenanceCharges: double.tryParse(_maintenanceController.text.trim()),
        areaSqft: null,
        bedrooms: _flatConfig.contains('1') ? 1 : _flatConfig.contains('3') ? 3 : _flatConfig.contains('4') ? 4 : 2,
        bathrooms: 1,
        features: [
          ..._roomFurnishing,
          ..._roomFeatures,
          ..._flatAmenities,
          ..._societyAmenities,
        ],
        mainImageUrl: _roomPhotoUrls.isNotEmpty ? _roomPhotoUrls.first : null,
        availableFrom: _availableFrom,
        genderPreference: _genderPreference,
        sharingType: _roomType,
      );

      // Include video tour URL as a feature tag if provided
      if (_videoTourUrl != null && !request.features.contains('video_tour')) {
        request = ListingCreateRequest(
          title: request.title,
          description: request.description,
          city: request.city,
          locality: request.locality,
          subLocality: request.subLocality,
          monthlyRent: request.monthlyRent,
          securityDeposit: request.securityDeposit,
          maintenanceCharges: request.maintenanceCharges,
          areaSqft: request.areaSqft,
          bedrooms: request.bedrooms,
          bathrooms: request.bathrooms,
          features: [...request.features, 'video_tour'],
          mainImageUrl: request.mainImageUrl,
          availableFrom: request.availableFrom,
          genderPreference: request.genderPreference,
          sharingType: request.sharingType,
        );
      }

      await ref.read(listingsRepositoryProvider).createListing(request);
      ref.invalidate(discoverListingsProvider);
      await ref.read(bootstrapControllerProvider.notifier).load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.postListingSuccess)),
      );
      context.go('/discover');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const totalSteps = 7;

    return Scaffold(
      appBar: AppBar(title: Text(locale.listingBuilderTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: List.generate(totalSteps, (i) {
                  final completed = i < _step;
                  final current = i == _step;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: completed || current
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Text(_stepEmojis[_step], style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _stepTitle(locale, _step),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${_step + 1}/$totalSteps',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                children: [_buildStep(_step)],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  child: Text(locale.backCta),
                ),
              ),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(
              flex: _step > 0 ? 2 : 1,
              child: GradientActionButton(
                key: Key(_step < totalSteps - 1 ? 'listing_next_step' : 'listing_submit_button'),
                label: _submitting
                    ? locale.postingInProgress
                    : (_step < totalSteps - 1 ? locale.onboardingNext : locale.publishListingCta),
                onPressed: _submitting
                    ? null
                    : (_step < totalSteps - 1
                        ? (_canProceed() ? () => setState(() => _step++) : null)
                        : _submit),
                icon: _step < totalSteps - 1
                    ? Icons.arrow_forward_rounded
                    : Icons.add_home_work_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepTitle(AppLocalizations locale, int step) {
    return switch (step) {
      0 => locale.listingStepLocation,
      1 => locale.listingStepSociety,
      2 => locale.listingStepRoom,
      3 => locale.listingStepFlat,
      4 => locale.listingStepCosts,
      5 => locale.listingStepAbout,
      6 => locale.reviewTitle,
      _ => '',
    };
  }

  Widget _buildStep(int step) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return switch (step) {
      0 => _buildLocationStep(theme, locale),
      1 => _buildSocietyStep(theme, locale),
      2 => _buildRoomStep(theme, locale),
      3 => _buildFlatStep(theme, locale),
      4 => _buildCostsStep(theme, locale),
      5 => _buildAboutStep(theme, locale),
      6 => _buildReviewStep(theme, locale),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildLocationStep(ThemeData theme, AppLocalizations locale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              key: const Key('listing_society_input'),
              controller: _societyController,
              decoration: InputDecoration(
                labelText: locale.societyBuildingLabel,
                prefixIcon: const Icon(Icons.apartment_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: locale.fullAddressLabel,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('listing_city_input'),
                    controller: _cityController,
                    decoration: InputDecoration(labelText: locale.cityLabel),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('listing_locality_input'),
                    controller: _localityController,
                    decoration: InputDecoration(labelText: locale.localityLabel),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocietyStep(ThemeData theme, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.societyTypeLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['gated', 'independent', 'co_living', 'pg'].map((type) {
                    return ChoiceChip(
                      label: Text(_societyTypeLabel(locale, type)),
                      selected: _societyType == type,
                      onSelected: (_) => setState(() => _societyType = type),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.societyAmenitiesLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _societyAmenityOptions.map((opt) {
                    final key = opt.$1;
                    final selected = _societyAmenities.contains(key);
                    return FilterChip(
                      avatar: Icon(opt.$2, size: 16),
                      label: Text(_amenityLabel(locale, key)),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        v ? _societyAmenities.add(key) : _societyAmenities.remove(key);
                      }),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.societyVibeLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _societyVibeOptions.map((opt) {
                    final key = opt.$1;
                    final selected = _societyVibeTags.contains(key);
                    return FilterChip(
                      avatar: Icon(opt.$2, size: 16),
                      label: Text(_vibeLabel(locale, key)),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        v ? _societyVibeTags.add(key) : _societyVibeTags.remove(key);
                      }),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomStep(ThemeData theme, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.roomTypeLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['private_room', 'shared_room', 'master_bedroom'].map((type) {
                    return ChoiceChip(
                      label: Text(_roomTypeLabel(locale, type)),
                      selected: _roomType == type,
                      onSelected: (_) => setState(() => _roomType = type),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.furnishingLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _furnishingOptions.map((opt) {
                    final selected = _roomFurnishing.contains(opt.$1);
                    return FilterChip(
                      avatar: Icon(opt.$2, size: 16),
                      label: Text(_furnishingLabel(locale, opt.$1)),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        v ? _roomFurnishing.add(opt.$1) : _roomFurnishing.remove(opt.$1);
                      }),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.roomFeaturesLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _roomFeatureOptions.map((opt) {
                    final selected = _roomFeatures.contains(opt.$1);
                    return FilterChip(
                      avatar: Icon(opt.$2, size: 16),
                      label: Text(_roomFeatureLabel(locale, opt.$1)),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        v ? _roomFeatures.add(opt.$1) : _roomFeatures.remove(opt.$1);
                      }),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(locale.roomPhotosLabel, style: theme.textTheme.titleMedium),
                    const Spacer(),
                    if (_roomPhotoUrls.length < 2)
                    InfoPill(label: locale.minPhotosRequired, highlighted: true),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ..._roomPhotoUrls.asMap().entries.map((e) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(e.value, width: 100, height: 100, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(width: 100, height: 100,
                              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.broken_image_outlined)),
                          ),
                        ),
                        Positioned(right: -4, top: -4,
                          child: Material(color: theme.colorScheme.error, shape: const CircleBorder(),
                            child: InkWell(onTap: () => setState(() => _roomPhotoUrls.removeAt(e.key)),
                              customBorder: const CircleBorder(),
                              child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, color: Colors.white, size: 14)),
                            ),
                          ),
                        ),
                      ],
                    )),
                    if (_roomPhotoUrls.length < 10)
                      Material(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _pickRoomPhotos,
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(height: 4),
                                Text(locale.addPhotoCta, style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.videoTourLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  locale.videoTourHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (_videoUploading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_videoTourUrl != null)
                  Row(
                    children: [
                      Icon(
                        Icons.videocam_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          locale.videoTourAdded,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _videoTourUrl = null),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  )
                else
                  Material(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickVideoTour,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.video_call_outlined,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                locale.addVideoCta,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickVideoTour() async {
    final service = ref.read(imageUploadServiceProvider);
    final file = await service.pickVideo();
    if (file == null) return;

    final validation = await service.validateVideo(file);
    if (!validation.isValid) {
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.tooLarge ? locale.videoTooLarge : locale.videoTooLong)),
      );
      return;
    }

    setState(() => _videoUploading = true);
    final url = await service.uploadVideoTour(file);
    setState(() {
      _videoTourUrl = url;
      _videoUploading = false;
    });
  }

  Widget _buildFlatStep(ThemeData theme, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.flatConfigLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['1BHK', '2BHK', '3BHK', '4BHK+', 'Studio'].map((config) {
                    return ChoiceChip(
                      label: Text(config),
                      selected: _flatConfig == config,
                      onSelected: (_) => setState(() => _flatConfig = config),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _floorController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: locale.floorLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _totalFloorsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: locale.totalFloorsLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.flatAmenitiesLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _flatAmenityOptions.map((opt) {
                    final selected = _flatAmenities.contains(opt.$1);
                    return FilterChip(
                      avatar: Icon(opt.$2, size: 16),
                      label: Text(_flatAmenityLabel(locale, opt.$1)),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        v ? _flatAmenities.add(opt.$1) : _flatAmenities.remove(opt.$1);
                      }),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostsStep(ThemeData theme, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('listing_rent_input'),
                        controller: _rentController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: locale.monthlyRentInputLabel,
                          prefixText: '₹ ',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _depositController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: locale.securityDepositLabel,
                          prefixText: '₹ ',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maintenanceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: locale.maintenanceLabel,
                          prefixText: '₹ ',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(locale.electricityLabel, style: theme.textTheme.titleSmall),
                          const SizedBox(height: 6),
                          SegmentedButton<String>(
                            segments: [
                              ButtonSegment(value: 'included', label: Text(locale.includedLabel)),
                              ButtonSegment(value: 'separate', label: Text(locale.separateLabel)),
                            ],
                            selected: {_electricityIncluded},
                            onSelectionChanged: (v) => setState(() => _electricityIncluded = v.first),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_electricityIncluded == 'separate') ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _electricityEstController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: locale.electricityEstLabel,
                      prefixText: '₹ ',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cookCostController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: locale.cookCostLabel,
                          prefixText: '₹ ',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maidCostController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: locale.maidCostLabel,
                          prefixText: '₹ ',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _setupCostController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: locale.setupCostLabel,
                    prefixText: '₹ ',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_totalMonthlyOutflow > 0)
          Card(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    locale.totalMonthlyOutflow('₹${_totalMonthlyOutflow.toStringAsFixed(0)}'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAboutStep(ThemeData theme, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.typicalDayLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _typicalDayController,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: locale.typicalDayHint,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.genderPreferenceLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'any', label: Text(locale.genderAny)),
                    ButtonSegment(value: 'male', label: Text(locale.genderMale)),
                    ButtonSegment(value: 'female', label: Text(locale.genderFemale)),
                  ],
                  selected: {_genderPreference},
                  onSelectionChanged: (v) => setState(() => _genderPreference = v.first),
                ),
                const SizedBox(height: 14),
                Text(locale.ageRangeLabel, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                RangeSlider(
                  values: RangeValues(_ageMin, _ageMax),
                  min: 18,
                  max: 50,
                  divisions: 32,
                  labels: RangeLabels('${_ageMin.round()}', '${_ageMax.round()}'),
                  onChanged: (v) => setState(() {
                    _ageMin = v.start;
                    _ageMax = v.end;
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(locale.nonNegotiablesTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _nonNegotiableOptions.map((key) {
                    final selected = _nonNegotiables.contains(key);
                    return FilterChip(
                      label: Text(_nonNegLabel(locale, key)),
                      selected: selected,
                      onSelected: selected
                          ? (_) => setState(() => _nonNegotiables.remove(key))
                          : _nonNegotiables.length < 3
                              ? (_) => setState(() => _nonNegotiables.add(key))
                              : null,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(locale.availableFromLabel, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        _availableFrom == null
                            ? locale.availableFromUnset
                            : DateFormat('d MMM yyyy', locale.localeName).format(_availableFrom!),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 180)),
                      initialDate: _availableFrom ?? DateTime.now().add(const Duration(days: 1)),
                    );
                    if (date != null) setState(() => _availableFrom = date);
                  },
                  child: Text(locale.selectDateCta),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep(ThemeData theme, AppLocalizations locale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReviewCard(
          title: locale.reviewLocation,
          icon: Icons.location_on_outlined,
          onEdit: () => setState(() => _step = 0),
          editLabel: locale.editStep,
          children: [
            if (_societyController.text.trim().isNotEmpty)
              Text(_societyController.text.trim(), style: theme.textTheme.bodyLarge),
            if (_addressController.text.trim().isNotEmpty)
              Text(_addressController.text.trim(), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text([_cityController.text.trim(), _localityController.text.trim()].where((s) => s.isNotEmpty).join(', '),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewCard(
          title: locale.reviewSociety,
          icon: Icons.apartment_outlined,
          onEdit: () => setState(() => _step = 1),
          editLabel: locale.editStep,
          children: [
            Text(_societyTypeLabel(locale, _societyType), style: theme.textTheme.bodyLarge),
            if (_societyAmenities.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _societyAmenities.map((a) => Chip(
                  label: Text(_amenityLabel(locale, a), style: theme.textTheme.bodySmall),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            if (_societyVibeTags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _societyVibeTags.map((v) => Chip(
                  label: Text(_vibeLabel(locale, v), style: theme.textTheme.bodySmall),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewCard(
          title: locale.reviewRoom,
          icon: Icons.bedroom_parent_outlined,
          onEdit: () => setState(() => _step = 2),
          editLabel: locale.editStep,
          children: [
            Text(_roomTypeLabel(locale, _roomType), style: theme.textTheme.bodyLarge),
            if (_roomFurnishing.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _roomFurnishing.map((f) => Chip(
                  label: Text(_furnishingLabel(locale, f), style: theme.textTheme.bodySmall),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            if (_roomFeatures.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _roomFeatures.map((f) => Chip(
                  label: Text(_roomFeatureLabel(locale, f), style: theme.textTheme.bodySmall),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            Text('${_roomPhotoUrls.length} photo${_roomPhotoUrls.length != 1 ? 's' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewCard(
          title: locale.reviewFlat,
          icon: Icons.home_work_outlined,
          onEdit: () => setState(() => _step = 3),
          editLabel: locale.editStep,
          children: [
            Text(_flatConfig, style: theme.textTheme.bodyLarge),
            if (_floorController.text.trim().isNotEmpty || _totalFloorsController.text.trim().isNotEmpty)
              Text('Floor ${_floorController.text.trim()} / ${_totalFloorsController.text.trim()}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (_flatAmenities.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _flatAmenities.map((a) => Chip(
                  label: Text(_flatAmenityLabel(locale, a), style: theme.textTheme.bodySmall),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewCard(
          title: locale.reviewCosts,
          icon: Icons.currency_rupee_rounded,
          onEdit: () => setState(() => _step = 4),
          editLabel: locale.editStep,
          children: [
            if (_rentController.text.trim().isNotEmpty)
              Text('Rent: ₹${_rentController.text.trim()}/mo', style: theme.textTheme.bodyLarge),
            if (_depositController.text.trim().isNotEmpty)
              Text('Deposit: ₹${_depositController.text.trim()}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (_maintenanceController.text.trim().isNotEmpty)
              Text('Maintenance: ₹${_maintenanceController.text.trim()}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (_totalMonthlyOutflow > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(locale.totalMonthlyOutflow('₹${_totalMonthlyOutflow.toStringAsFixed(0)}'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _ReviewCard(
          title: locale.reviewAbout,
          icon: Icons.person_outline,
          onEdit: () => setState(() => _step = 5),
          editLabel: locale.editStep,
          children: [
            if (_typicalDayController.text.trim().isNotEmpty)
              Text(_typicalDayController.text.trim(), maxLines: 2, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium),
            Text('Gender: ${_genderPreference == 'any' ? locale.genderAny : _genderPreference == 'male' ? locale.genderMale : locale.genderFemale}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Text('Age: ${_ageMin.round()} - ${_ageMax.round()}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (_nonNegotiables.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _nonNegotiables.map((n) => Chip(
                  label: Text(_nonNegLabel(locale, n), style: theme.textTheme.bodySmall),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            if (_availableFrom != null)
              Text('Move-in: ${DateFormat('d MMM yyyy', locale.localeName).format(_availableFrom!)}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }

  String _societyTypeLabel(AppLocalizations l, String v) => switch (v) {
    'gated' => l.societyTypeGated,
    'independent' => l.societyTypeIndependent,
    'co_living' => l.societyTypeCoLiving,
    _ => l.societyTypePg,
  };

  String _amenityLabel(AppLocalizations l, String k) => switch (k) {
    'pool' => l.amenityPool,
    'gym' => l.amenityGym,
    'clubhouse' => l.amenityClubhouse,
    'sports' => l.amenitySports,
    'parking' => l.amenityParking,
    'power_backup' => l.amenityPowerBackup,
    'water_backup' => l.amenityWaterBackup,
    'security' => l.amenitySecurity,
    'lift' => l.amenityLift,
    'cctv' => l.amenityCctv,
    'visitor_entry' => l.amenityVisitorEntry,
    'garden' => l.amenityGarden,
    _ => humanizeFlatmatesToken(k),
  };

  String _vibeLabel(AppLocalizations l, String k) => switch (k) {
    'bachelor_friendly' => l.vibeBachelorFriendly,
    'quiet' => l.vibeQuiet,
    'active_community' => l.vibeActiveCommunity,
    'family_dominant' => l.vibeFamilyDominant,
    'pet_friendly' => l.vibePetFriendly,
    'visitor_friendly' => l.vibeVisitorFriendly,
    _ => humanizeFlatmatesToken(k),
  };

  String _furnishingLabel(AppLocalizations l, String k) => switch (k) {
    'bed' => l.furnishingBed,
    'wardrobe' => l.furnishingWardrobe,
    'ac' => l.furnishingAc,
    'geyser' => l.furnishingGeyser,
    'study_table' => l.furnishingStudyTable,
    'curtains' => l.furnishingCurtains,
    _ => humanizeFlatmatesToken(k),
  };

  String _roomFeatureLabel(AppLocalizations l, String k) => switch (k) {
    'attached_bathroom' => l.featureAttachedBathroom,
    'private_balcony' => l.roomFeatureBalcony,
    'window_sunlight' => l.roomFeatureSunlight,
    'storage_space' => l.roomFeatureStorage,
    _ => humanizeFlatmatesToken(k),
  };

  String _flatAmenityLabel(AppLocalizations l, String k) => switch (k) {
    'wifi' => l.featureWifi,
    'washing_machine' => l.featureWashingMachine,
    'refrigerator' => l.amenityRefrigerator,
    'microwave' => l.amenityMicrowave,
    'tv' => l.amenityTv,
    'dining_table' => l.amenityDiningTable,
    'sofa' => l.amenitySofa,
    'kitchen_equipped' => l.amenityKitchenEquipped,
    _ => humanizeFlatmatesToken(k),
  };

  String _roomTypeLabel(AppLocalizations l, String v) => switch (v) {
    'private_room' => l.sharingPrivateRoom,
    'shared_room' => l.sharingSharedRoom,
    _ => l.roomTypeMasterBedroom,
  };

  String _nonNegLabel(AppLocalizations l, String k) => switch (k) {
    'food_veg_only' => l.nonNegVegOnly,
    'no_smoking' => l.nonNegNoSmoking,
    'no_drinking' => l.nonNegNoDrinking,
    'no_overnight_guests' => l.nonNegNoGuests,
    'no_pets' => l.nonNegNoPets,
    'no_parties' => l.nonNegNoParties,
    'min_tidy' => l.nonNegMinTidy,
    _ => humanizeFlatmatesToken(k),
  };
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.editLabel,
    required this.children,
  });

  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final String editLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                TextButton(
                  onPressed: onEdit,
                  child: Text(editLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
