const express = require("express");
const asyncHandler = require("../middlewares/asyncHandler");
const validateRequest = require("../middlewares/validateRequest");
const { authenticate } = require("../middlewares/auth.middleware");
const productController = require("../controllers/product.controller");
const {
  listQueryValidation,
  uuidParam,
  createProductValidation,
  updateProductValidation,
} = require("../validators/product.validator");

const router = express.Router();

router.get(
  "/",
  listQueryValidation,
  validateRequest,
  asyncHandler(productController.list)
);

router.get(
  "/me",
  authenticate,
  listQueryValidation,
  validateRequest,
  asyncHandler(productController.listMine)
);

router.get(
  "/:id",
  ...uuidParam,
  validateRequest,
  asyncHandler(productController.getById)
);

router.post(
  "/",
  authenticate,
  createProductValidation,
  validateRequest,
  asyncHandler(productController.create)
);

router.put(
  "/:id",
  authenticate,
  ...updateProductValidation,
  validateRequest,
  asyncHandler(productController.update)
);

router.delete(
  "/:id",
  authenticate,
  ...uuidParam,
  validateRequest,
  asyncHandler(productController.remove)
);

module.exports = router;
