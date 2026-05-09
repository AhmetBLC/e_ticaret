const express = require("express");
const asyncHandler = require("../middlewares/asyncHandler");
const validateRequest = require("../middlewares/validateRequest");
const { authenticate } = require("../middlewares/auth.middleware");
const orderController = require("../controllers/order.controller");
const {
  listQueryValidation,
  createOrderValidation,
  orderIdParam,
  advanceOrderStatusValidation,
} = require("../validators/order.validator");

const router = express.Router();

router.post(
  "/",
  authenticate,
  createOrderValidation,
  validateRequest,
  asyncHandler(orderController.create)
);

router.get(
  "/",
  authenticate,
  listQueryValidation,
  validateRequest,
  asyncHandler(orderController.list)
);

router.get(
  "/stats",
  authenticate,
  asyncHandler(orderController.getStats)
);

router.patch(
  "/:id/status",
  authenticate,
  ...orderIdParam,
  advanceOrderStatusValidation,
  validateRequest,
  asyncHandler(orderController.advanceStatus)
);

module.exports = router;
