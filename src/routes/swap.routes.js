const express = require("express");
const asyncHandler = require("../middlewares/asyncHandler");
const validateRequest = require("../middlewares/validateRequest");
const { authenticate } = require("../middlewares/auth.middleware");
const swapController = require("../controllers/swap.controller");
const {
  swapListQueryValidation,
  createSwapValidation,
  swapIdParam,
} = require("../validators/swap.validator");

const router = express.Router();

router.get(
  "/",
  authenticate,
  swapListQueryValidation,
  validateRequest,
  asyncHandler(swapController.list)
);

router.post(
  "/",
  authenticate,
  createSwapValidation,
  validateRequest,
  asyncHandler(swapController.create)
);

router.put(
  "/:id/accept",
  authenticate,
  swapIdParam,
  validateRequest,
  asyncHandler(swapController.accept)
);

router.put(
  "/:id/reject",
  authenticate,
  swapIdParam,
  validateRequest,
  asyncHandler(swapController.reject)
);

module.exports = router;
