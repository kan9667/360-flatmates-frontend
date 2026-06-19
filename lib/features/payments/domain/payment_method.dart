import '../data/payment_method_dto.dart';

/// Domain model for a saved payment method. Free of JSON / data-layer
/// concerns so it can be reused by presentation widgets.
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.methodType,
    this.brand,
    this.last4,
    this.nickname,
    this.isDefault = false,
    this.createdAt,
  });

  final int id;
  final String methodType;
  final String? brand;
  final String? last4;
  final String? nickname;
  final bool isDefault;
  final DateTime? createdAt;

  factory PaymentMethod.fromDto(PaymentMethodDto dto) => PaymentMethod(
        id: dto.id,
        methodType: dto.methodType,
        brand: dto.brand,
        last4: dto.last4,
        nickname: dto.nickname,
        isDefault: dto.isDefault,
        createdAt: dto.createdAt,
      );

  PaymentMethod copyWith({
    String? nickname,
    bool? isDefault,
  }) {
    return PaymentMethod(
      id: id,
      methodType: methodType,
      brand: brand,
      last4: last4,
      nickname: nickname ?? this.nickname,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
    );
  }
}

/// Display label for a payment-method `method_type`. The backend stores
/// `card`, `upi`, `netbanking`, `wallet`, `emandate`, `cardless_emi`,
/// `paylater`, etc. (Razorpay method enum). Anything we don't recognize
/// falls back to a generic "Other" label.
String paymentMethodBrandLabel(String rawBrand) {
  final normalized = rawBrand.toLowerCase();
  switch (normalized) {
    case 'card':
    case 'credit_card':
    case 'debit_card':
      return 'Card';
    case 'upi':
      return 'UPI';
    case 'netbanking':
      return 'Net banking';
    case 'wallet':
      return 'Wallet';
    default:
      return 'Other';
  }
}
