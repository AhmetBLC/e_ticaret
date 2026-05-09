const conversationModel = require("../models/conversation.model");
const messageModel = require("../models/message.model");
const productModel = require("../models/product.model");
const AppError = require("../utils/AppError");

async function getMyConversations(userId) {
  const conversations = await conversationModel.findUserConversations(userId);
  return conversations;
}

async function getChatMessages(userId, conversationId, query = {}) {
  const conv = await conversationModel.findConversationById(conversationId);
  if (!conv) {
    throw new AppError("Conversation not found", 404, "NOT_FOUND");
  }
  
  if (conv.buyer_id !== userId && conv.seller_id !== userId) {
    throw new AppError("You do not have access to this conversation", 403, "FORBIDDEN");
  }

  const limit = parseInt(query.limit) || 100;
  const offset = parseInt(query.offset) || 0;
  
  const messages = await messageModel.findMessagesByConversationId(conversationId, limit, offset);
  
  // Mark as read in background
  messageModel.markMessagesAsRead(conversationId, userId).catch(err => console.error("Error marking messages as read:", err));

  return messages;
}

async function sendMessage(userId, { productId, conversationId, text }) {
  if (!text || text.trim().length === 0) {
    throw new AppError("Message text is required", 400, "VALIDATION_ERROR");
  }

  let conv;

  if (conversationId) {
    conv = await conversationModel.findConversationById(conversationId);
    if (!conv) {
      throw new AppError("Conversation not found", 404, "NOT_FOUND");
    }
    if (conv.buyer_id !== userId && conv.seller_id !== userId) {
      throw new AppError("You do not have access to this conversation", 403, "FORBIDDEN");
    }
  } else if (productId) {
    const product = await productModel.findProductById(productId);
    if (!product) {
      throw new AppError("Product not found", 404, "NOT_FOUND");
    }

    if (product.user_id === userId) {
      throw new AppError("You cannot message yourself", 400, "VALIDATION_ERROR");
    }

    // Find or create conversation
    conv = await conversationModel.findConversationByParticipants(userId, product.user_id, productId);
    if (!conv) {
      conv = await conversationModel.insertConversation({
        buyerId: userId,
        sellerId: product.user_id,
        productId: productId
      });
    }
  } else {
    throw new AppError("Either productId or conversationId is required", 400, "VALIDATION_ERROR");
  }

  const message = await messageModel.insertMessage({
    conversationId: conv.id,
    senderId: userId,
    text: text.trim()
  });

  return { conversation: conv, message };
}

module.exports = {
  getMyConversations,
  getChatMessages,
  sendMessage,
};
