class CreateOrderResult {
  final String orderId;
  final String status;
  final bool isPaid;
  final String paymentMethod;
  final double total;
  final bool requiresPayOs;

  const CreateOrderResult({
    required this.orderId,
    required this.status,
    required this.isPaid,
    required this.paymentMethod,
    required this.total,
    required this.requiresPayOs,
  });

  factory CreateOrderResult.fromJson(Map<String, dynamic> json) {
    return CreateOrderResult(
      orderId: '${json['orderId'] ?? json['id'] ?? ''}',
      status: json['status'] as String? ?? 'PENDING',
      isPaid: json['isPaid'] == true,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      requiresPayOs: json['requiresPayOs'] == true,
    );
  }
}
