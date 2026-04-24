import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class VisitItem {
  const VisitItem({
    required this.id,
    required this.propertyTitle,
    required this.status,
    required this.scheduledDate,
    required this.visitContext,
  });

  final int id;
  final String propertyTitle;
  final String status;
  final DateTime scheduledDate;
  final String visitContext;

  factory VisitItem.fromJson(Map<String, dynamic> json) {
    final property = Map<String, dynamic>.from(
      json['property'] as Map? ?? const {},
    );
    return VisitItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      propertyTitle: property['title'] as String? ?? 'Visit',
      status: json['status'] as String? ?? 'scheduled',
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      visitContext: json['visit_context'] as String? ?? 'property_tour',
    );
  }
}

class VisitsRepository {
  const VisitsRepository(this._ref);

  final Ref _ref;

  Future<List<VisitItem>> fetchVisits() async {
    final response = await _ref.watch(apiClientProvider).get('/visits');
    final data = Map<String, dynamic>.from(response.data as Map);
    final visits = (data['visits'] as List? ?? const []);
    return visits
        .map(
          (item) => VisitItem.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> scheduleFlatmateVisit({
    required int propertyId,
    required int counterpartyUserId,
    required int conversationId,
    required DateTime scheduledDate,
  }) async {
    await _ref
        .watch(apiClientProvider)
        .post(
          '/visits',
          data: {
            'property_id': propertyId,
            'scheduled_date': scheduledDate.toUtc().toIso8601String(),
            'visit_context': 'flatmate_meet',
            'counterparty_user_id': counterpartyUserId,
            'conversation_id': conversationId,
          },
        );
  }

  Future<void> confirmVisit(int visitId) async {
    await _ref
        .watch(apiClientProvider)
        .put('/visits/$visitId', data: {'status': 'confirmed'});
  }

  Future<void> rescheduleVisit(int visitId, DateTime newDate) async {
    await _ref
        .watch(apiClientProvider)
        .put('/visits/$visitId', data: {
          'scheduled_date': newDate.toUtc().toIso8601String(),
          'status': 'requested',
        });
  }

  Future<void> cancelVisit(int visitId) async {
    await _ref
        .watch(apiClientProvider)
        .put('/visits/$visitId', data: {'status': 'cancelled'});
  }
}

final visitsRepositoryProvider = Provider<VisitsRepository>(
  (ref) => VisitsRepository(ref),
);

final visitsProvider = FutureProvider<List<VisitItem>>(
  (ref) => ref.watch(visitsRepositoryProvider).fetchVisits(),
);
