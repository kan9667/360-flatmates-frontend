import 'package:flatmates_app/app/router/app_router.dart';
import 'package:flatmates_app/features/auth/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  group('authenticatedAppReady', () {
    test('treats active backend stage as ready', () {
      expect(
        authenticatedAppReady(
          authStage: AuthStage.active,
          hasCompletedOnboardingLocally: false,
        ),
        isTrue,
      );
    });

    test('treats local onboarding completion as ready during stale gate', () {
      expect(
        authenticatedAppReady(
          authStage: AuthStage.appOnboarding,
          hasCompletedOnboardingLocally: true,
        ),
        isTrue,
      );
    });

    test('keeps stale app onboarding gate when no local completion exists', () {
      expect(
        authenticatedAppReady(
          authStage: AuthStage.appOnboarding,
          hasCompletedOnboardingLocally: false,
        ),
        isFalse,
      );
    });
  });

  group('authenticatedIdentifierVerificationRedirect', () {
    test('sends completed authenticated auth routes to discover', () {
      final profile = fakeBootstrapData().profile;

      final redirect = authenticatedIdentifierVerificationRedirect(
        location: '/login',
        isAuthRoute: true,
        isSplash: false,
        profile: profile,
        hasCompletedOnboardingLocally: false,
      );

      expect(redirect, '/discover');
    });

    test('keeps profile completion gate when full name is missing', () {
      final profile = fakeBootstrapData().profile.copyWith(fullName: '');

      final redirect = authenticatedIdentifierVerificationRedirect(
        location: '/login',
        isAuthRoute: true,
        isSplash: false,
        profile: profile,
        hasCompletedOnboardingLocally: false,
      );

      expect(redirect, '/complete-profile');
    });

    test('redirects to onboarding when blocked route is accessed', () {
      final profile = fakeBootstrapData().profile.copyWith(
        onboardingCompleted: false,
      );

      final redirect = authenticatedIdentifierVerificationRedirect(
        location: '/swipe',
        isAuthRoute: false,
        isSplash: false,
        profile: profile,
        hasCompletedOnboardingLocally: false,
      );

      expect(redirect, '/onboarding');
    });

    test('allows non-blocked routes through when onboarding is incomplete', () {
      final profile = fakeBootstrapData().profile.copyWith(
        onboardingCompleted: false,
      );

      final redirect = authenticatedIdentifierVerificationRedirect(
        location: '/discover',
        isAuthRoute: false,
        isSplash: false,
        profile: profile,
        hasCompletedOnboardingLocally: false,
      );

      expect(redirect, isNull);
    });

    test('sends auth routes to discover when onboarding is incomplete', () {
      final profile = fakeBootstrapData().profile.copyWith(
        onboardingCompleted: false,
      );

      final redirect = authenticatedIdentifierVerificationRedirect(
        location: '/login',
        isAuthRoute: true,
        isSplash: false,
        profile: profile,
        hasCompletedOnboardingLocally: false,
      );

      expect(redirect, '/discover');
    });

    test('allows deep links through after local gates are satisfied', () {
      final profile = fakeBootstrapData().profile;

      final redirect = authenticatedIdentifierVerificationRedirect(
        location: '/chats/123',
        isAuthRoute: false,
        isSplash: false,
        profile: profile,
        hasCompletedOnboardingLocally: false,
      );

      expect(redirect, isNull);
    });

    test(
      'uses local completion when identifier verification mirror is stale',
      () {
        final profile = fakeBootstrapData().profile.copyWith(
          onboardingCompleted: false,
        );

        final redirect = authenticatedIdentifierVerificationRedirect(
          location: '/onboarding',
          isAuthRoute: false,
          isSplash: false,
          profile: profile,
          hasCompletedOnboardingLocally: true,
        );

        expect(redirect, '/discover');
      },
    );
  });

  group('isOnboardingBlockedRoute', () {
    test('blocks swipe deck', () {
      expect(isOnboardingBlockedRoute('/swipe'), isTrue);
    });

    test('blocks post and post/new', () {
      expect(isOnboardingBlockedRoute('/post'), isTrue);
      expect(isOnboardingBlockedRoute('/post/new'), isTrue);
    });

    test('blocks conversations list but not individual chat threads', () {
      expect(isOnboardingBlockedRoute('/chats'), isTrue);
      expect(isOnboardingBlockedRoute('/chats/123'), isFalse);
    });

    test('allows discover, map, profile, settings, and deep links', () {
      expect(isOnboardingBlockedRoute('/discover'), isFalse);
      expect(isOnboardingBlockedRoute('/map'), isFalse);
      expect(isOnboardingBlockedRoute('/profile'), isFalse);
      expect(isOnboardingBlockedRoute('/profile/edit'), isFalse);
      expect(isOnboardingBlockedRoute('/profile/settings'), isFalse);
      expect(isOnboardingBlockedRoute('/onboarding'), isFalse);
      expect(isOnboardingBlockedRoute('/complete-profile'), isFalse);
      expect(isOnboardingBlockedRoute('/notifications'), isFalse);
      expect(isOnboardingBlockedRoute('/flat-details/123'), isFalse);
    });
  });
}
