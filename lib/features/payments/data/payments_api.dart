import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/endpoints.dart';
import '../../../core/providers.dart';
import '../../../core/utils/paged_envelope.dart';
import 'payment_method_dto.dart';
import 'razorpay_order_dto.dart';

/// Thin wrapper around the payments REST surface. All methods are async and
/// propagate typed [AppFailure]s via the shared [ApiClient].
class PaymentsApi {
  const PaymentsApi(this._ref);

  final Ref _ref;

  /// `POST /payments/razorpay/order` — kicks off a hosted checkout flow for
  /// the supplied booking. The backend mints a Razorpay order id and (when
  /// configured) returns a hosted checkout URL the client can open via
  /// `url_launcher`.
  Future<RazorpayOrderResponseDto> createRazorpayOrder(int bookingId) async {
    final response = await _ref.read(apiClientProvider).post(
          FlatmatesEndpoints.paymentRazorpayOrder,
          data: RazorpayOrderDto(bookingId: bookingId).toJson(),
        );
    final data = response.data;
    if (data is! Map) {
      throw StateError(
        'Unexpected payload shape from '
        '${FlatmatesEndpoints.paymentRazorpayOrder}: ${data.runtimeType}',
      );
    }
    return RazorpayOrderResponseDto.fromJson(Map<String, dynamic>.from(data));
  }

  /// `POST /payments/razorpay/verify` — forwards the Razorpay identifiers
  /// collected by `Razorpay.js` / `RazorpayCheckout` so the backend can
  /// verify the HMAC signature and capture the payment.
  Future<void> verifyRazorpayPayment({
    required int bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    await _ref.read(apiClientProvider).post(
          FlatmatesEndpoints.paymentRazorpayVerify,
          data: RazorpayVerifyDto(
            bookingId: bookingId,
            razorpayOrderId: razorpayOrderId,
            razorpayPaymentId: razorpayPaymentId,
            razorpaySignature: razorpaySignature,
          ).toJson(),
        );
  }

  /// `GET /payments/methods` — list the user's saved payment methods using
  /// cursor pagination. Mirrors the standard `{ items, next_cursor, ... }`
  /// envelope used by every other list endpoint.
  Future<
      ({
        List<PaymentMethodDto> items,
        String? nextCursor,
        bool hasMore,
      })> listPaymentMethods({String? cursor, int limit = 20}) async {
    final queryParameters = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }
    final response = await _ref.read(apiClientProvider).get(
          FlatmatesEndpoints.paymentMethods,
          queryParameters: queryParameters,
        );
    final data = Map<String, dynamic>.from(response.data as Map? ?? const {});
    return parsePagedEnvelope(
      data,
      PaymentMethodDto.fromJson,
      label: 'paymentMethods',
    );
  }

  /// `POST /payments/methods` — persist a tokenized payment method. Real
  /// card capture is expected to happen via Razorpay.js in the web client
  /// (or the Razorpay Flutter SDK on mobile); only the resulting token is
  /// forwarded to the backend here.
  Future<PaymentMethodDto> addPaymentMethod(
    PaymentMethodCreateDto request,
  ) async {
    final response = await _ref.read(apiClientProvider).post(
          FlatmatesEndpoints.paymentMethods,
          data: request.toJson(),
        );
    final data = response.data;
    if (data is! Map) {
      throw StateError(
        'Unexpected payload shape from ${FlatmatesEndpoints.paymentMethods}: '
        '${data.runtimeType}',
      );
    }
    return PaymentMethodDto.fromJson(Map<String, dynamic>.from(data));
  }

  /// `PUT /payments/methods/{id}` — change nickname and/or default flag.
  Future<PaymentMethodDto> updatePaymentMethod(
    int id,
    PaymentMethodUpdateDto request,
  ) async {
    final response = await _ref.read(apiClientProvider).put(
          FlatmatesEndpoints.paymentMethod(id),
          data: request.toJson(),
        );
    final data = response.data;
    if (data is! Map) {
      throw StateError(
        'Unexpected payload shape from ${FlatmatesEndpoints.paymentMethod(id)}: '
        '${data.runtimeType}',
      );
    }
    return PaymentMethodDto.fromJson(Map<String, dynamic>.from(data));
  }

  /// `DELETE /payments/methods/{id}` — remove a saved method.
  Future<void> deletePaymentMethod(int id) async {
    await _ref
        .read(apiClientProvider)
        .delete(FlatmatesEndpoints.paymentMethod(id));
  }
}

final paymentsApiProvider = Provider<PaymentsApi>((ref) {
  if (kDebugMode) {
    debugPrint('PaymentsApi initialised');
  }
  return PaymentsApi(ref);
});
