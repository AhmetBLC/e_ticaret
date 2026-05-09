const express = require("express");
const asyncHandler = require("../middlewares/asyncHandler");
const validateRequest = require("../middlewares/validateRequest");
const { authenticate, requireRole } = require("../middlewares/auth.middleware");
const { ROLES } = require("../constants/roles");
const categoryController = require("../controllers/category.controller");
const {
  categoryIdParam,
  createCategoryValidation,
  updateCategoryValidation,
} = require("../validators/category.validator");

const router = express.Router();

// Public: list all categories (tree or flat)
router.get("/", asyncHandler(categoryController.list));

// Admin only: create, update, delete
router.post(
  "/",
  authenticate,
  requireRole(ROLES.ADMIN),
  createCategoryValidation,
  validateRequest,
  asyncHandler(categoryController.create)
);

router.put(
  "/:id",
  authenticate,
  requireRole(ROLES.ADMIN),
  ...updateCategoryValidation,
  validateRequest,
  asyncHandler(categoryController.update)
);

router.delete(
  "/:id",
  authenticate,
  requireRole(ROLES.ADMIN),
  ...categoryIdParam,
  validateRequest,
  asyncHandler(categoryController.remove)
);

module.exports = router;
