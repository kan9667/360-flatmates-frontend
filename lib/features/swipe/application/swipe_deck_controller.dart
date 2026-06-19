import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../discover/discover_repository.dart';
import '../swipe_repository.dart';

/// Snapshot of the swipe deck state.
///
/// The deck renders at most `limit` profiles at a time. When the user nears
/// the end of the current deck, [SwipeDeckController.loadMore] is invoked
/// to fetch the next page using cursor pagination from the backend.
class SwipeDeckState {
  const SwipeDeckState({
    this.profiles = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<SwipeProfile> profiles;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  bool get hasError => error != null;
  bool get isEmpty => profiles.isEmpty && !isLoading;

  SwipeDeckState copyWith({
    List<SwipeProfile>? profiles,
    String? nextCursor,
    bool setNextCursorNull = false,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) {
    return SwipeDeckState(
      profiles: profiles ?? this.profiles,
      nextCursor: setNextCursorNull ? null : (nextCursor ?? this.nextCursor),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SwipeDeckController extends Notifier<SwipeDeckState> {
  final Set<int> _swipedUserIds = {};
  bool _loadInFlight = false;

  /// Whether the user has swiped at least one profile in the current deck.
  /// Lets the UI distinguish "end of deck" from "no profiles ever loaded".
  bool get hasSwiped => _swipedUserIds.isNotEmpty;

  @override
  SwipeDeckState build() {
    // Reload the deck whenever shared discover filters (location, radius,
    // move-in, ...) change from the swipe header or the explore page.
    ref.watch(discoverFiltersProvider);
    Future.microtask(() => _load());
    return const SwipeDeckState(isLoading: true);
  }

  Future<void> _load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = const SwipeDeckState(isLoading: true);
    try {
      final filters = ref.read(discoverFiltersProvider);
      if (kDebugMode) {
        log('[SwipeDeck] Loading profiles, filters=$filters');
      } else {
        log('[SwipeDeck] Loading profiles');
      }
      final page = await ref
          .read(swipeRepositoryProvider)
          .fetchSwipeProfilesPage(filters: filters);
      if (kDebugMode) {
        log('[SwipeDeck] Loaded ${page.items.length} profiles');
      } else {
        log('[SwipeDeck] Loaded ${page.items.length} profiles');
      }
      final filtered = page.items
          .where((p) => !_swipedUserIds.contains(p.id))
          .toList();
      state = state.copyWith(
        profiles: filtered,
        nextCursor: page.nextCursor,
        setNextCursorNull: page.nextCursor == null,
        hasMore: page.hasMore,
        isLoading: false,
        clearError: true,
      );
    } catch (e, st) {
      if (kDebugMode) {
        log('[SwipeDeck] ERROR loading profiles: $e', error: e, stackTrace: st);
      } else {
        log('[SwipeDeck] ERROR loading profiles');
      }
      state = state.copyWith(isLoading: false, error: e);
    } finally {
      _loadInFlight = false;
    }
  }

  /// Appends the next page of profiles to the deck. Safe against re-entry:
  /// repeated calls while a load is in flight or after the stream has been
  /// fully drained are dropped.
  Future<void> loadMore() async {
    if (_loadInFlight || state.isLoadingMore || !state.hasMore) return;
    final cursor = state.nextCursor;
    if (cursor == null) return;
    _loadInFlight = true;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final filters = ref.read(discoverFiltersProvider);
      final page = await ref
          .read(swipeRepositoryProvider)
          .fetchSwipeProfilesPage(filters: filters, cursor: cursor);
      final existingIds = state.profiles.map((p) => p.id).toSet();
      final newProfiles = page.items
          .where((p) =>
              !_swipedUserIds.contains(p.id) && !existingIds.contains(p.id))
          .toList();
      state = state.copyWith(
        profiles: [...state.profiles, ...newProfiles],
        nextCursor: page.nextCursor,
        setNextCursorNull: page.nextCursor == null,
        hasMore: page.hasMore,
        isLoadingMore: false,
      );
    } catch (e, st) {
      log('[SwipeDeck] ERROR loading more profiles: $e',
          error: e, stackTrace: st);
      state = state.copyWith(isLoadingMore: false, error: e);
    } finally {
      _loadInFlight = false;
    }
  }

  void markSwiped(int userId) {
    _swipedUserIds.add(userId);
    final current = state.profiles;
    if (current.isNotEmpty) {
      state = state.copyWith(
        profiles: current.where((p) => p.id != userId).toList(),
      );
    }
  }

  void undoSwipe(SwipeProfile profile) {
    final wasSwiped = _swipedUserIds.remove(profile.id);
    if (!wasSwiped) return;
    final current = state.profiles;
    state = state.copyWith(profiles: [profile, ...current]);
  }

  Future<void> refresh() async {
    _swipedUserIds.clear();
    await _load();
  }
}

final swipeDeckControllerProvider =
    NotifierProvider<SwipeDeckController, SwipeDeckState>(
      SwipeDeckController.new,
    );
