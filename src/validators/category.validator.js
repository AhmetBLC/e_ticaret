const { body, param } = require("express-validator");

const categoryIdParam = [
  param("id").isUUID().withMessage("Invalid category id"),
];

const createCategoryValidation = [
  body("name")
    .trim()
    .notEmpty()
    .withMessage("Category name is required")
    .isLength({ max: 255 })
    .withMessage("Name must be 255 characters or less"),
  body("parent_id")
    .optional({ nullable: true })
    .isUUID()
    .withMessage("parent_id must be a valid UUID"),
];

const updateCategoryValidation = [
  ...categoryIdParam,
  body("name")
    .optional()
    .trim()
    .notEmpty()
    .withMessage("Name cannot be empty")
    .isLength({ max: 255 })
    .withMessage("Name must be 255 characters or less"),
  body("parent_id")
    .optional({ nullable: true })
    .isUUID()
    .withMessage("parent_id must be a valid UUID"),
];

module.exports = {
  categoryIdParam,
  createCategoryValidation,
  updateCategoryValidation,
};
