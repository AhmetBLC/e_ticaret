const express = require("express");
const asyncHandler = require("../middlewares/asyncHandler");
const { authenticate } = require("../middlewares/auth.middleware");
const profileController = require("../controllers/profile.controller");

const router = express.Router();

router.get("/", authenticate, asyncHandler(profileController.getProfile));

module.exports = router;
