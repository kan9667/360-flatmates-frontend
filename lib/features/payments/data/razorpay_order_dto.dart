/// DTO + serialization for Razorpay checkout order creation and verification.
///
/// Mirrors `app/schemas/payment.py::RazorpayOrderRequest`,
/// `RazorpayOrderResponse`, and `RazorpayVerifyRequest`. We treat the order
/// payload as opaque on the client — the client only consumes the order id,
/// amount, currency, and the hosted checkout URL — and forwards the
/// Razorpay-issued identifiers back to the backend for signature
/// verification.
class RazorpayOrderDto {
  const RazorpayOrderDto({
    required this.bookingId,
  });

  final int bookingId;

  Map<String, dynamic> toJson() => {'booking_id': bookingId};
}

class RazorpayOrderResponseDto {
  const RazorpayOrderResponseDto({
    required this.orderId,
    required this.amount,
    required this.currency,
    this.receipt,
    this.status,
    this.checkoutUrl,
    this.raw = const <String, dynamic>{},
  });

  final String orderId;
  final num amount;
  final String currency;
  final String? receipt;
  final String? status;
  final String? checkoutUrl;
  final Map<String, dynamic> raw;

  factory RazorpayOrderResponseDto.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderResponseDto(
      orderId: json['order_id']?.toString() ?? '',
      amount: (json['amount'] as num?) ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      receipt: json['receipt'] as String?,
      status: json['status'] as String?,
      checkoutUrl: json['checkout_url'] as String?,
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'amount': amount,
        'currency': currency,
        if (receipt != null) 'receipt': receipt,
        if (status != null) 'status': status,
        if (checkoutUrl != null) 'checkout_url': checkoutUrl,
      };
}

class RazorpayVerifyDto {
  const RazorpayVerifyDto({
    required this.bookingId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  final int bookingId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  Map<String, dynamic> toJson() => {
        'booking_id': bookingId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      };
}
