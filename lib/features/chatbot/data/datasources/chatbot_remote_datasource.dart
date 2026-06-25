import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class ChatbotReply {
  final String reply;
  final bool suggestStaff;
  final List<String> productIds;

  ChatbotReply({
    required this.reply,
    this.suggestStaff = false,
    this.productIds = const [],
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

    return ChatbotReply(
      reply: data['reply'] as String? ?? '',
      suggestStaff: data['suggestStaff'] as bool? ?? false,
      productIds: (data['productIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
