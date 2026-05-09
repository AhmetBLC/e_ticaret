const express = require("express");
const asyncHandler = require("../middlewares/asyncHandler");
const validateRequest = require("../middlewares/validateRequest");
const { authenticate, requireRole } = require("../middlewares/auth.middleware");
const { ROLES } = require("../constants/roles");
const shipmentController = require("../controllers/shipment.controller");
const {
  shipmentIdParam,
  trackingParam,
  advanceStatusValidation,
} = require("../validators/shipment.validator");

const router = express.Router();

// Public: track by tracking number
router.get(
  "/track/:trackingNumber",
  ...trackingParam,
  validateRequest,
  asyncHandler(shipmentController.track)
);

// My shipments (requires auth)
router.get(
  "/",
  authenticate,
  asyncHandler(shipmentController.myShipments)
);

// Admin: all shipments
router.get(
  "/all",
  authenticate,
  requireRole(ROLES.ADMIN),
  asyncHandler(shipmentController.listAll)
);

// Shipment detail (requires auth)
router.get(
  "/:id",
  authenticate,
  ...shipmentIdParam,
  validateRequest,
  asyncHandler(shipmentController.getById)
);

// Advance shipment status (admin or seller)
router.patch(
  "/:id/status",
  authenticate,
  ...advanceStatusValidation,
  validateRequest,
  asyncHandler(shipmentController.advanceStatus)
);

// Simulate full delivery (demo/test only)
router.post(
  "/:id/simulate-delivery",
  authenticate,
  ...shipmentIdParam,
  validateRequest,
  asyncHandler(shipmentController.simulateDelivery)
);

router.post(
  "/initiate/:workOrderId",
  authenticate,
  requireRole(ROLES.ADMIN),
  asyncHandler(shipmentController.initiate)
);

module.exports = router;
