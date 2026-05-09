const express = require("express");
const chatController = require("../controllers/chat.controller");
const { authenticate } = require("../middlewares/auth.middleware");
const asyncHandler = require("../middlewares/asyncHandler");

const router = express.Router();

router.use(authenticate);

router.get("/conversations", asyncHandler(chatController.getMyConversations));
router.get("/conversations/:conversationId/messages", asyncHandler(chatController.getMessages));
router.post("/messages", asyncHandler(chatController.sendMessage));

module.exports = router;
