import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../l10n/gen/app_localizations.dart';
import '../chats/chats_repository.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/flatmates_ui.dart';

class MapViewPage extends ConsumerStatefulWidget {
  const MapViewPage({super.key});

  @override
  ConsumerState<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends ConsumerState<MapViewPage> {
  double _budgetMin = 5000;
  double _budgetMax = 100000;
  String _roomType = 'all';
  String _moveInFilter = 'all';
  String _genderPref = 'any';
  bool _verifiedOnly = false;

  static const _defaultCenter = LatLng(12.9716, 77.5946); // Bangalore

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(discoverListingsProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _FilterBar(
              budgetMin: _budgetMin,
              budgetMax: _budgetMax,
              roomType: _roomType,
              moveInFilter: _moveInFilter,
              genderPref: _genderPref,
              verifiedOnly: _verifiedOnly,
              onBudgetChanged: (min, max) => setState(() {
                _budgetMin = min;
                _budgetMax = max;
              }),
              onRoomTypeChanged: (v) => setState(() => _roomType = v),
              onMoveInChanged: (v) => setState(() => _moveInFilter = v),
              onGenderChanged: (v) => setState(() => _genderPref = v),
              onVerifiedChanged: (v) => setState(() => _verifiedOnly = v),
            ),
            Expanded(
              child: listings.when(
                data: (items) {
                  final filtered = _applyFilters(items);
                  final markers = _buildMarkers(filtered, theme);
                  return Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: _defaultCenter,
                          zoom: 12,
                        ),
                        markers: markers,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                      if (filtered.isEmpty)
                        Center(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Text(
                                items.isEmpty ? locale.emptyListings : locale.noListingsMatchFilters,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers(List<PropertyListing> items, ThemeData theme) {
    // In V1 without geocoding data on listings, we show markers for
    // items that have locality information. Position is approximated
    // by a hash of the locality string for visual distribution.
    final markers = <Marker>{};
    for (final item in items) {
      if (item.locality == null || item.locality!.trim().isEmpty) continue;

      // Deterministic position offset based on locality hash
      final hash = item.locality!.hashCode;
      final lat = 12.9716 + ((hash & 0xFF) - 128) * 0.001;
      final lng = 77.5946 + (((hash >> 8) & 0xFF) - 128) * 0.001;
      final isRoom = item.ownerId != null;

      markers.add(Marker(
        markerId: MarkerId('listing_${item.id}'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isRoom ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueBlue,
        ),
        infoWindow: InfoWindow(
          title: item.title,
          snippet: item.monthlyRent != null
              ? '₹${item.monthlyRent!.toStringAsFixed(0)}/mo'
              : null,
        ),
        onTap: () => _showListingSheet(item),
      ));
    }
    return markers;
  }

  List<PropertyListing> _applyFilters(List<PropertyListing> items) {
    return items.where((item) {
      // Budget filter
      if (item.monthlyRent != null) {
        if (item.monthlyRent! < _budgetMin || item.monthlyRent! > _budgetMax) {
          return false;
        }
      }

      // Room type filter
      if (_roomType != 'all') {
        if (item.sharingType != _roomType) return false;
      }

      // Gender preference filter
      if (_genderPref != 'any') {
        if (item.genderPreference != null &&
            item.genderPreference != 'any' &&
            item.genderPreference != _genderPref) {
          return false;
        }
      }

      // Move-in / availability filter
      if (_moveInFilter == 'immediate') {
        if (item.availableFrom != null &&
            item.availableFrom!.isAfter(
              DateTime.now().add(const Duration(days: 7)),
            )) {
          return false;
        }
      }

      // Verified filter
      if (_verifiedOnly) {
        final isVerified = item.features.contains('verified') ||
            item.features.contains('is_verified');
        if (!isVerified) return false;
      }

      return true;
    }).toList();
  }

  void _showListingSheet(PropertyListing item) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (item.mainImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        item.mainImageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.apartment_rounded),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.apartment_rounded),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: theme.textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (item.monthlyRent != null)
                          Text(
                            '₹${item.monthlyRent!.toStringAsFixed(0)}/mo',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (item.locality != null)
                          Text(item.locality!, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (item.bedrooms != null)
                    InfoPill(icon: Icons.bed_outlined, label: locale.homeBedsValue(item.bedrooms!)),
                  if (item.bathrooms != null)
                    InfoPill(icon: Icons.bathtub_outlined, label: locale.homeBathsValue(item.bathrooms!)),
                  if (item.genderPreference != null)
                    InfoPill(icon: Icons.group_outlined, label: localizedFlatmatesGenderLabel(locale, item.genderPreference!)),
                  if (item.sharingType != null)
                    InfoPill(icon: Icons.meeting_room_outlined, label: localizedFlatmatesSharingTypeLabel(locale, item.sharingType!)),
                ],
              ),
              const SizedBox(height: 16),
              GradientActionButton(
                label: locale.likeListingCta,
                onPressed: () async {
                  final conversationId = await ref
                      .read(discoverRepositoryProvider)
                      .likeListing(item.id);
                  ref.invalidate(discoverListingsProvider);
                  ref.invalidate(conversationsProvider);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(conversationId == null
                        ? locale.contactRequestSent
                        : locale.contactRequestWithConversation(conversationId))),
                  );
                },
                icon: Icons.favorite_border_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.budgetMin,
    required this.budgetMax,
    required this.roomType,
    required this.moveInFilter,
    required this.genderPref,
    required this.verifiedOnly,
    required this.onBudgetChanged,
    required this.onRoomTypeChanged,
    required this.onMoveInChanged,
    required this.onGenderChanged,
    required this.onVerifiedChanged,
  });

  final double budgetMin;
  final double budgetMax;
  final String roomType;
  final String moveInFilter;
  final String genderPref;
  final bool verifiedOnly;
  final void Function(double, double) onBudgetChanged;
  final void Function(String) onRoomTypeChanged;
  final void Function(String) onMoveInChanged;
  final void Function(String) onGenderChanged;
  final void Function(bool) onVerifiedChanged;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ActionChip(
              avatar: const Icon(Icons.currency_rupee_rounded, size: 16),
              label: Text('₹${budgetMin.toStringAsFixed(0)}-₹${budgetMax.toStringAsFixed(0)}'),
              onPressed: () => _showBudgetDialog(context),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(locale.sharingPrivateRoom),
              selected: roomType == 'private_room',
              onSelected: (_) => onRoomTypeChanged(roomType == 'private_room' ? 'all' : 'private_room'),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(locale.sharingSharedRoom),
              selected: roomType == 'shared_room',
              onSelected: (_) => onRoomTypeChanged(roomType == 'shared_room' ? 'all' : 'shared_room'),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(locale.genderAny),
              selected: genderPref == 'any',
              onSelected: (_) => onGenderChanged('any'),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: Text(locale.timelineImmediate),
              selected: moveInFilter == 'immediate',
              onSelected: (_) => onMoveInChanged(moveInFilter == 'immediate' ? 'all' : 'immediate'),
            ),
            const SizedBox(width: 8),
            FilterChip(
              avatar: Icon(Icons.verified_outlined, size: 16),
              label: Text(locale.verifiedFilterLabel),
              selected: verifiedOnly,
              onSelected: (_) => onVerifiedChanged(!verifiedOnly),
            ),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context) {
    final locale = AppLocalizations.of(context);
    double min = budgetMin;
    double max = budgetMax;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(locale.monthlyBudgetLabel),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RangeSlider(
                values: RangeValues(min, max),
                min: 5000,
                max: 100000,
                divisions: 19,
                labels: RangeLabels('₹${min.toStringAsFixed(0)}', '₹${max.toStringAsFixed(0)}'),
                onChanged: (v) => setDialogState(() {
                  min = v.start;
                  max = v.end;
                }),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(locale.cancelCta)),
            FilledButton(
              onPressed: () {
                onBudgetChanged(min, max);
                Navigator.pop(ctx);
              },
              child: Text(locale.commonSave),
            ),
          ],
        ),
      ),
    );
  }
}
