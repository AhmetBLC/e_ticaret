import '../../data/datasources/remote/chat_remote_datasource.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';

abstract class ChatRepository {
  Future<List<ConversationModel>> getConversations();
  Future<List<MessageModel>> getMessages(String conversationId);
  Future<void> sendMessage({String? productId, String? conversationId, required String text});
}

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remote);

  final ChatRemoteDatasource _remote;

  @override
  Future<List<ConversationModel>> getConversations() async {
    final data = await _remote.fetchConversations();
    return data.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    final data = await _remote.fetchMessages(conversationId);
    return data.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> sendMessage({String? productId, String? conversationId, required String text}) async {
    await _remote.sendMessage(
      productId: productId,
      conversationId: conversationId,
      text: text,
    );
  }
}
