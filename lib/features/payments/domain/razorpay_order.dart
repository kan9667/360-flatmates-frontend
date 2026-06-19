import '../data/razorpay_order_dto.dart';

/// Domain wrapper around the Razorpay order response. The actual checkout
/// happens via the Razorpay-hosted page (or `RazorpayCheckout` SDK), so
/// the client only cares about the order id, amount, currency, and any
/// prebuilt checkout URL.
class RazorpayOrder {
  const RazorpayOrder({
    required this.orderId,
    required this.amount,
    required this.currency,
    this.receipt,
    this.status,
    this.checkoutUrl,
  });

  final String orderId;
  final num amount;
  final String currency;
  final String? receipt;
  final String? status;
  final String? checkoutUrl;

  factory RazorpayOrder.fromDto(RazorpayOrderResponseDto dto) => RazorpayOrder(
        orderId: dto.orderId,
        amount: dto.amount,
        currency: dto.currency,
        receipt: dto.receipt,
        status: dto.status,
        checkoutUrl: dto.checkoutUrl,
      );
}
