const express = require("express");
const asyncHandler = require("../middlewares/asyncHandler");
const validateRequest = require("../middlewares/validateRequest");
const { authenticate, requireRole } = require("../middlewares/auth.middleware");
const { ROLES } = require("../constants/roles");
const paymentController = require("../controllers/payment.controller");
const {
  paymentIdParam,
  initiatePaymentValidation,
} = require("../validators/payment.validator");

const router = express.Router();

// Initiate a payment (requires auth)
router.post(
  "/",
  authenticate,
  initiatePaymentValidation,
  validateRequest,
  asyncHandler(paymentController.initiate)
);

// Complete 3D Secure verification (simulated callback)
router.post(
  "/:id/verify-3ds",
  ...paymentIdParam,
  validateRequest,
  asyncHandler(paymentController.verify3DS)
);

// Payment history (requires auth)
router.get(
  "/history",
  authenticate,
  asyncHandler(paymentController.history)
);

// Get payment details
router.get(
  "/:id",
  authenticate,
  ...paymentIdParam,
  validateRequest,
  asyncHandler(paymentController.getById)
);

// Refund a payment (admin only)
router.post(
  "/:id/refund",
  authenticate,
  requireRole(ROLES.ADMIN),
  ...paymentIdParam,
  validateRequest,
  asyncHandler(paymentController.refund)
);

module.exports = router;
