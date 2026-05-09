const { query } = require("../config/database");

const MSG_SELECT = "id, conversation_id, sender_id, text, is_read, created_at";

async function insertMessage({ conversationId, senderId, text }) {
  const r = await query(
    "INSERT INTO messages (conversation_id, sender_id, text) VALUES ($1, $2, $3) RETURNING " + MSG_SELECT,
    [conversationId, senderId, text]
  );
  return r.rows[0];
}

async function findMessagesByConversationId(conversationId, limit = 50, offset = 0) {
  const r = await query(
    "SELECT " + MSG_SELECT + " FROM messages WHERE conversation_id = $1 ORDER BY created_at ASC LIMIT $2 OFFSET $3",
    [conversationId, limit, offset]
  );
  return r.rows;
}

async function markMessagesAsRead(conversationId, readerId) {
  await query(
    "UPDATE messages SET is_read = TRUE WHERE conversation_id = $1 AND sender_id != $2 AND is_read = FALSE",
    [conversationId, readerId]
  );
}

module.exports = {
  insertMessage,
  findMessagesByConversationId,
  markMessagesAsRead,
};
