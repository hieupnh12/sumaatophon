import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class ChatbotProductSuggestion {
  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final int stockQuantity;

  const ChatbotProductSuggestion({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl = '',
    this.stockQuantity = 0,
  });

  factory ChatbotProductSuggestion.fromJson(Map<String, dynamic> json) {
    return ChatbotProductSuggestion(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatbotReply {
  final String reply;
  final bool suggestStaff;
  final List<String> productIds;
  final List<ChatbotProductSuggestion> products;

  ChatbotReply({
    required this.reply,
    this.suggestStaff = false,
    this.productIds = const [],
    this.products = const [],
  });
}

class ChatbotRemoteDataSource {
  final ApiClient apiClient;

  ChatbotRemoteDataSource(this.apiClient);

  Future<List<String>> fetchSuggestions() async {
    final data = await apiClient.get(ApiEndpoints.chatbotSuggestions);
    if (data is! Map<String, dynamic>) return const [];
    final list = data['suggestions'];
    if (list is! List) return const [];
    return list.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
  }

  Future<ChatbotReply> ask(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    final data = await apiClient.post(
      ApiEndpoints.chatbotAsk,
      body: {
        'message': message.trim(),
        if (history.isNotEmpty) 'history': history,
      },
    );

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid chatbot response');
    }

    final productsRaw = data['products'];
    final products = productsRaw is List
        ? productsRaw
            .whereType<Map>()
            .map((e) => ChatbotProductSuggestion.fromJson(Map<String, dynamic>.from(e)))
            .where((p) => p.id.isNotEmpty)
            .toList()
        : const <ChatbotProductSuggestion>[];

    return ChatbotReply(
      reply: data['reply'] as String? ?? '',
      suggestStaff: data['suggestStaff'] as bool? ?? false,
      productIds: (data['productIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      products: products,
    );
  }
}
