import 'api_client.dart';

class ChatRemoteDatasource {
  ChatRemoteDatasource(this._client);

  final ApiClient _client;

  Future<List<dynamic>> fetchConversations() async {
    final body = await _client.get('chat/conversations');
    return body['data'] as List<dynamic>;
  }

  Future<List<dynamic>> fetchMessages(String conversationId) async {
    if (conversationId.isEmpty) return [];
    final body = await _client.get('chat/conversations/$conversationId/messages');
    return body['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage({
    String? productId,
    String? conversationId,
    required String text,
  }) async {
    final body = await _client.post('chat/messages', {
      if (productId != null && productId.isNotEmpty) 'productId': productId,
      if (conversationId != null && conversationId.isNotEmpty) 'conversationId': conversationId,
      'text': text,
    });
    return body['data'] as Map<String, dynamic>;
  }
}
