const express = require("express");
const asyncHandler = require("../middlewares/asyncHandler");
const validateRequest = require("../middlewares/validateRequest");
const { optionalAuthenticate } = require("../middlewares/optionalAuth.middleware");
const checkoutController = require("../controllers/checkout.controller");
const { checkoutValidation } = require("../validators/checkout.validator");

const router = express.Router();

// One-page checkout: address + payment + order in one call
// Authentication is optional to support Guest Checkout
router.post(
  "/",
  optionalAuthenticate,
  checkoutValidation,
  validateRequest,
  asyncHandler(checkoutController.checkout)
);

module.exports = router;
