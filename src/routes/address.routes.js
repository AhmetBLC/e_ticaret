const express = require("express");
const asyncHandler = require("../middlewares/asyncHandler");
const validateRequest = require("../middlewares/validateRequest");
const { authenticate } = require("../middlewares/auth.middleware");
const addressController = require("../controllers/address.controller");
const {
  addressIdParam,
  createAddressValidation,
  updateAddressValidation,
} = require("../validators/address.validator");

const router = express.Router();

// All address routes require authentication
router.use(authenticate);

router.get("/", asyncHandler(addressController.list));

router.get(
  "/:id",
  ...addressIdParam,
  validateRequest,
  asyncHandler(addressController.get)
);

router.post(
  "/",
  createAddressValidation,
  validateRequest,
  asyncHandler(addressController.create)
);

router.put(
  "/:id",
  ...updateAddressValidation,
  validateRequest,
  asyncHandler(addressController.update)
);

router.delete(
  "/:id",
  ...addressIdParam,
  validateRequest,
  asyncHandler(addressController.remove)
);

module.exports = router;
