const { body, param } = require("express-validator");
const { SHIPMENT_STATUS } = require("../constants/shipmentStatus");

const shipmentIdParam = [
  param("id").isUUID().withMessage("Invalid shipment id"),
];

const trackingParam = [
  param("trackingNumber").notEmpty().withMessage("Tracking number required"),
];

const advanceStatusValidation = [
  ...shipmentIdParam,
  body("status")
    .isIn(Object.values(SHIPMENT_STATUS))
    .withMessage("Invalid shipment status"),
];

module.exports = { shipmentIdParam, trackingParam, advanceStatusValidation };
