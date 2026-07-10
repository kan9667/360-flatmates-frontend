import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ChatsRepository', () {
    test('chat realtime code does not reference removed Supabase tables', () {
      final source = File(
        'lib/features/chats/chats_repository.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('user_conversations')));
      expect(source, isNot(contains('user_messages')));
      expect(source, contains("'messages'"));
    });

    test(
      'fetchMessages uses before_id and MessageListResponse envelope',
      () async {
        final adapter = _CapturingAdapter(
          responseBody: {
            'messages': [
              {
                'id': 8,
                'conversation_id': 42,
                'sender_id': 44,
                'body': 'older',
                'message_type': 'text',
                'created_at': '2026-06-30T07:00:00Z',
              },
              {
                'id': 9,
                'conversation_id': 42,
                'sender_id': 44,
                'body': 'hello',
                'message_type': 'text',
                'created_at': '2026-06-30T08:00:00Z',
              },
            ],
            'total': 2,
            'has_more': true,
          },
        );
        final apiClient = ApiClient(
          baseUrl: 'https://api.test.example.com',
          tokenProvider: FakeAuthTokenProvider(),
        );
        apiClient.dio.httpClientAdapter = adapter;
        final container = ProviderContainer(
          overrides: [apiClientProvider.overrideWithValue(apiClient)],
        );
        addTearDown(container.dispose);

        final page = await container
            .read(chatsRepositoryProvider)
            .fetchMessages(42, beforeId: 20);

        expect(
          adapter.lastRequest?.path,
          FlatmatesEndpoints.conversationMessages(42),
        );
        expect(adapter.lastRequest?.queryParameters['before_id'], 20);
        expect(adapter.lastRequest?.queryParameters['limit'], 50);
        expect(page.messages, hasLength(2));
        expect(page.messages.first.id, 8);
        expect(page.messages.last.id, 9);
        expect(page.hasMore, isTrue);
        // Oldest id becomes the next before_id keyset cursor.
        expect(page.nextBeforeId, 8);
        expect(page.total, 2);
      },
    );

    test('fetchMessages ignores CursorPage-shaped payloads', () async {
      final adapter = _CapturingAdapter(
        responseBody: {
          'items': [
            {
              'id': 9,
              'conversation_id': 42,
              'sender_id': 44,
              'body': 'hello',
              'message_type': 'text',
              'created_at': '2026-06-30T08:00:00Z',
            },
          ],
          'next_cursor': null,
          'has_more': false,
          'limit': 30,
        },
      );
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);

      final page = await container
          .read(chatsRepositoryProvider)
          .fetchMessages(42);

      expect(page.messages, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextBeforeId, isNull);
    });

    test('watchMessages emits the REST seed page', () async {
      final adapter = _CapturingAdapter(
        responseBody: {
          'messages': [
            {
              'id': 9,
              'conversation_id': 42,
              'sender_id': 44,
              'body': 'hello',
              'message_type': 'text',
              'created_at': '2026-06-30T08:00:00Z',
            },
          ],
          'total': 1,
          'has_more': false,
        },
      );
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);

      final stream = container.read(chatsRepositoryProvider).watchMessages(42);
      final messages = await stream.first;

      expect(
        adapter.lastRequest?.path,
        FlatmatesEndpoints.conversationMessages(42),
      );
      expect(
        adapter.lastRequest?.queryParameters.containsKey('before_id'),
        isFalse,
      );
      expect(messages, hasLength(1));
      expect(messages.single.id, 9);
      expect(messages.single.conversationId, 42);
    });

    test('fetchIncomingLikes reads backend likes payload', () async {
      final adapter = _CapturingAdapter(
        responseBody: {
          'items': [
            {
              'id': 7,
              'peer': {
                'id': 44,
                'full_name': 'Incoming User',
                'profile_image_url': 'https://example.com/p.jpg',
                'mode': 'seeker',
                'city': 'Gurugram',
                'match_percentage': 91,
              },
              'context_property': {
                'id': 99,
                'title': 'Sunny room',
                'monthly_rent': 18000,
              },
              'created_at': '2026-05-07T08:30:00Z',
            },
          ],
          'next_cursor': null,
          'has_more': false,
          'limit': 20,
        },
      );
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);

      final likes = await container
          .read(chatsRepositoryProvider)
          .fetchIncomingLikes();

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.incomingLikes);
      expect(adapter.lastRequest?.method, 'GET');
      expect(likes, hasLength(1));
      expect(likes.first.id, 7);
      expect(likes.first.peer.id, 44);
      expect(likes.first.peer.fullName, 'Incoming User');
      expect(likes.first.contextProperty?.id, 99);
    });

    test('matchIncomingLike posts reciprocal profile swipe', () async {
      final adapter = _CapturingAdapter(responseBody: {'conversation_id': 123});
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);

      final conversationId = await container
          .read(chatsRepositoryProvider)
          .matchIncomingLike(peerId: 44, contextPropertyId: 99);

      expect(conversationId, 123);
      expect(adapter.lastRequest?.path, FlatmatesEndpoints.swipes);
      expect(adapter.lastRequest?.method, 'POST');
      expect(adapter.lastRequest?.data, {
        'target_type': 'user',
        'action': 'like',
        'target_user_id': 44,
        'context_property_id': 99,
      });
    });

    test('submitQnA posts backend-compatible nested numeric answers', () async {
      final adapter = _CapturingAdapter();
      final apiClient = ApiClient(
        baseUrl: 'https://api.test.example.com',
        tokenProvider: FakeAuthTokenProvider(),
      );
      apiClient.dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(apiClient)],
      );
      addTearDown(container.dispose);

      await container.read(chatsRepositoryProvider).submitQnA(42, {
        'q1': '  Quiet home near work  ',
        'q2': '3',
        'q3': ' Clean kitchen ',
      });

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.conversationQnA(42));
      expect(adapter.lastRequest?.method, 'POST');
      expect(adapter.lastRequest?.data, {
        'answers': {
          '0': 'Quiet home near work',
          '1': '3',
          '2': 'Clean kitchen',
        },
      });
    });
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({this.responseBody = const {}});

  final Object responseBody;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(responseBody),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
