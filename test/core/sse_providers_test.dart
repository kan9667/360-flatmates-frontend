import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/network/flatmates_realtime_service.dart';
import 'package:flatmates_app/core/network/sse_providers.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/notifications/notifications_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Realtime event routing', () {
    late _CountingAdapter adapter;
    late ProviderContainer container;

    setUp(() {
      adapter = _CountingAdapter();
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = adapter;
      container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);
    });

    test('extracts conversation ids from chat routes', () {
      expect(conversationIdFromRoute('/chats/42'), 42);
      expect(conversationIdFromRoute('flatmates://app/chats/42'), 42);
      expect(conversationIdFromRoute('/home'), isNull);
      expect(conversationIdFromRoute('/chats/not-a-number'), isNull);
    });

    test(
      'flatmate_new_message refreshes conversations and thread messages',
      () async {
        await container.read(conversationsProvider.future);
        await container.read(messagesProvider(42).future);
        final conversationsBefore = adapter.count(
          'GET',
          FlatmatesEndpoints.conversations,
        );
        final messagesBefore = adapter.count(
          'GET',
          FlatmatesEndpoints.conversationMessages(42),
        );

        _route(
          container,
          const FlatmatesRealtimeEvent(
            type: 'new_notification',
            data: {'type_key': 'flatmate_new_message', 'route': '/chats/42'},
          ),
        );
        await container.pump();

        await container.read(conversationsProvider.future);
        await container.read(messagesProvider(42).future);
        expect(
          adapter.count('GET', FlatmatesEndpoints.conversations),
          greaterThan(conversationsBefore),
        );
        expect(
          adapter.count('GET', FlatmatesEndpoints.conversationMessages(42)),
          greaterThan(messagesBefore),
        );
      },
    );

    test('flatmate_new_match refreshes conversations and like tabs', () async {
      await container.read(conversationsProvider.future);
      await container.read(incomingLikesProvider.future);
      await container.read(outgoingLikesProvider.future);
      final conversationsBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.conversations,
      );
      final incomingBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.incomingLikes,
      );
      final outgoingBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.outgoingLikes,
      );

      _route(
        container,
        const FlatmatesRealtimeEvent(
          type: 'new_notification',
          data: {'type_key': 'flatmate_new_match'},
        ),
      );
      await container.pump();

      await container.read(conversationsProvider.future);
      await container.read(incomingLikesProvider.future);
      await container.read(outgoingLikesProvider.future);

      expect(
        adapter.count('GET', FlatmatesEndpoints.conversations),
        greaterThan(conversationsBefore),
      );
      expect(
        adapter.count('GET', FlatmatesEndpoints.incomingLikes),
        greaterThan(incomingBefore),
      );
      expect(
        adapter.count('GET', FlatmatesEndpoints.outgoingLikes),
        greaterThan(outgoingBefore),
      );
    });

    test(
      'new_message event invalidates messages seed for conversation',
      () async {
        await container.read(conversationsProvider.future);
        await container.read(messagesProvider(42).future);
        final messagesBefore = adapter.count(
          'GET',
          FlatmatesEndpoints.conversationMessages(42),
        );

        _route(
          container,
          const FlatmatesRealtimeEvent(
            type: 'new_message',
            data: {'conversation_id': 42, 'message_id': 99},
          ),
        );
        await container.pump();

        await container.read(messagesProvider(42).future);
        expect(
          adapter.count('GET', FlatmatesEndpoints.conversationMessages(42)),
          greaterThan(messagesBefore),
        );
        expect(
          adapter.count('GET', FlatmatesEndpoints.conversations),
          greaterThan(1),
        );
      },
    );

    test('new_match events refresh conversations and like tabs', () async {
      await container.read(conversationsProvider.future);
      await container.read(incomingLikesProvider.future);
      await container.read(outgoingLikesProvider.future);
      final conversationsBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.conversations,
      );
      final incomingBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.incomingLikes,
      );
      final outgoingBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.outgoingLikes,
      );

      _route(
        container,
        const FlatmatesRealtimeEvent(type: 'new_match', data: {'match_id': 1}),
      );
      await container.pump();

      await container.read(conversationsProvider.future);
      await container.read(incomingLikesProvider.future);
      await container.read(outgoingLikesProvider.future);

      expect(
        adapter.count('GET', FlatmatesEndpoints.conversations),
        greaterThan(conversationsBefore),
      );
      expect(
        adapter.count('GET', FlatmatesEndpoints.incomingLikes),
        greaterThan(incomingBefore),
      );
      expect(
        adapter.count('GET', FlatmatesEndpoints.outgoingLikes),
        greaterThan(outgoingBefore),
      );
    });

    test('generic notifications refresh notifications only', () async {
      await container.read(notificationsProvider.future);
      await container.read(conversationsProvider.future);
      final notifBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.notifications,
      );
      final convBefore = adapter.count(
        'GET',
        FlatmatesEndpoints.conversations,
      );

      _route(
        container,
        const FlatmatesRealtimeEvent(
          type: 'new_notification',
          data: {'type_key': 'flatmate_listing_approved'},
        ),
      );
      await container.pump();

      await container.read(notificationsProvider.future);
      await container.read(conversationsProvider.future);

      // Invalidates both legacy notificationsProvider and the list controller
      // (each may refetch once).
      expect(
        adapter.count('GET', FlatmatesEndpoints.notifications),
        greaterThan(notifBefore),
      );
      expect(
        adapter.count('GET', FlatmatesEndpoints.conversations),
        convBefore,
      );
    });
  });
}

void _route(ProviderContainer container, FlatmatesRealtimeEvent event) {
  final triggerProvider = Provider<void>((ref) {
    routeFlatmatesRealtimeEvent(ref, event);
  });
  container.read(triggerProvider);
}

class _CountingAdapter implements HttpClientAdapter {
  final List<String> _requests = [];

  int count(String method, String path) =>
      _requests.where((r) => r == '$method $path').length;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    _requests.add('${options.method} ${options.path}');
    return ResponseBody.fromString(
      jsonEncode(_bodyFor(options.path)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Object _bodyFor(String path) {
    if (path == FlatmatesEndpoints.conversationMessages(42)) {
      return {
        'messages': [
          {
            'id': 1,
            'conversation_id': 42,
            'sender_id': 44,
            'body': 'hello',
            'message_type': 'text',
            'created_at': '2026-06-30T08:00:00Z',
          },
        ],
        'total': 1,
        'has_more': false,
      };
    }
    return {
      'items': <Object>[],
      'next_cursor': null,
      'has_more': false,
      'limit': 20,
    };
  }
}
