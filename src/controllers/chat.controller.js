const chatService = require("../services/chat.service");

async function getMyConversations(req, res) {
  const data = await chatService.getMyConversations(req.user.id);
  res.json({ success: true, data });
}

async function getMessages(req, res) {
  const data = await chatService.getChatMessages(req.user.id, req.params.conversationId, req.query);
  res.json({ success: true, data });
}

async function sendMessage(req, res) {
  const data = await chatService.sendMessage(req.user.id, req.body);
  res.status(201).json({ success: true, data });
}

module.exports = {
  getMyConversations,
  getMessages,
  sendMessage,
};
