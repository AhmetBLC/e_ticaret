const express = require("express");
const asyncHandler = require("../middlewares/asyncHandler");
const validateRequest = require("../middlewares/validateRequest");
const {
  registerValidation,
  loginValidation,
} = require("../validators/auth.validator");
const authController = require("../controllers/auth.controller");

const router = express.Router();

router.post(
  "/register",
  registerValidation,
  validateRequest,
  asyncHandler(authController.register)
);

router.post(
  "/login",
  loginValidation,
  validateRequest,
  asyncHandler(authController.login)
);

module.exports = router;
