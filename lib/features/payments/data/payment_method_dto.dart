/// DTO + serialization for the Razorpay payment-method domain model.
///
/// The backend returns the canonical shape from
/// `app/schemas/payment.py::PaymentMethodOut`. Unknown keys are preserved
/// on [raw] so callers can evolve without coordinating a schema bump.
class PaymentMethodDto {
  const PaymentMethodDto({
    required this.id,
    required this.methodType,
    this.brand,
    this.last4,
    this.nickname,
    this.isDefault = false,
    this.createdAt,
    this.raw = const <String, dynamic>{},
  });

  final int id;
  final String methodType;
  final String? brand;
  final String? last4;
  final String? nickname;
  final bool isDefault;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  factory PaymentMethodDto.fromJson(Map<String, dynamic> json) {
    return PaymentMethodDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      methodType: json['method_type'] as String? ?? 'card',
      brand: json['brand'] as String?,
      last4: json['last4'] as String?,
      nickname: json['nickname'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'method_type': methodType,
        if (brand != null) 'brand': brand,
        if (last4 != null) 'last4': last4,
        if (nickname != null) 'nickname': nickname,
        'is_default': isDefault,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };
}

/// Payload for `POST /payments/methods` (tokenized via Razorpay.js on web).
class PaymentMethodCreateDto {
  const PaymentMethodCreateDto({
    required this.methodType,
    this.brand,
    this.last4,
    this.razorpayToken,
    this.razorpayPaymentId,
    this.nickname,
    this.isDefault = false,
  });

  final String methodType;
  final String? brand;
  final String? last4;
  final String? razorpayToken;
  final String? razorpayPaymentId;
  final String? nickname;
  final bool isDefault;

  Map<String, dynamic> toJson() => {
        'method_type': methodType,
        if (brand != null) 'brand': brand,
        if (last4 != null) 'last4': last4,
        if (razorpayToken != null) 'razorpay_token': razorpayToken,
        if (razorpayPaymentId != null) 'razorpay_payment_id': razorpayPaymentId,
        if (nickname != null) 'nickname': nickname,
        'is_default': isDefault,
      };
}

/// Payload for `PUT /payments/methods/{id}` — only mutable fields.
class PaymentMethodUpdateDto {
  const PaymentMethodUpdateDto({this.nickname, this.isDefault});

  final String? nickname;
  final bool? isDefault;

  Map<String, dynamic> toJson() => {
        if (nickname != null) 'nickname': nickname,
        if (isDefault != null) 'is_default': isDefault,
      };
}
