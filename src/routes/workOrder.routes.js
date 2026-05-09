const express = require("express");
const asyncHandler = require("../middlewares/asyncHandler");
const validateRequest = require("../middlewares/validateRequest");
const { authenticate, requireRole } = require("../middlewares/auth.middleware");
const { ROLES } = require("../constants/roles");
const workOrderController = require("../controllers/workOrder.controller");
const {
  listQueryValidation,
  workOrderIdParam,
} = require("../validators/workOrder.validator");

const router = express.Router();

router.get(
  "/",
  authenticate,
  requireRole(ROLES.ADMIN),
  listQueryValidation,
  validateRequest,
  asyncHandler(workOrderController.list)
);

router.put(
  "/:id/approve",
  authenticate,
  requireRole(ROLES.ADMIN),
  workOrderIdParam,
  validateRequest,
  asyncHandler(workOrderController.approve)
);

router.put(
  "/:id/reject",
  authenticate,
  requireRole(ROLES.ADMIN),
  workOrderIdParam,
  validateRequest,
  asyncHandler(workOrderController.reject)
);

module.exports = router;
