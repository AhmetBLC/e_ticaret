import 'package:flutter/foundation.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider(this._repository);

  final ChatRepository _repository;

  List<ConversationModel> _conversations = [];
  List<MessageModel> _activeMessages = [];
  bool _loading = false;
  String? _error;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get activeMessages => _activeMessages;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadConversations() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _conversations = await _repository.getConversations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String conversationId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _activeMessages = await _repository.getMessages(conversationId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage({String? productId, String? conversationId, required String text}) async {
    try {
      await _repository.sendMessage(
        productId: productId,
        conversationId: conversationId,
        text: text,
      );
      // If we have conversationId, reload messages
      if (conversationId != null && conversationId.isNotEmpty) {
        await loadMessages(conversationId);
      } else {
        await loadConversations();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
