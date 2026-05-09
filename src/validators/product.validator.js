const { body, param, query } = require("express-validator");

const listQueryValidation = [
  query("page")
    .optional()
    .isInt({ min: 1 })
    .withMessage("page must be a positive integer"),
  query("limit")
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage("limit must be between 1 and 100"),
];

const uuidParam = [
  param("id").isUUID().withMessage("Invalid product id"),
];

const createProductValidation = [
  body("title")
    .trim()
    .notEmpty()
    .withMessage("Title is required")
    .isLength({ max: 500 })
    .withMessage("Title must be at most 500 characters"),
  body("description")
    .optional({ nullable: true })
    .isString()
    .withMessage("description must be a string"),
  body("price")
    .notEmpty()
    .withMessage("price is required")
    .isFloat({ min: 0 })
    .withMessage("price must be a number >= 0"),
  body("category_id")
    .optional({ nullable: true })
    .isUUID()
    .withMessage("category_id must be a valid UUID"),
  body("variants")
    .optional({ nullable: true })
    .isArray()
    .withMessage("variants must be an array"),
];

const updateProductValidation = [
  ...uuidParam,
  body("title")
    .optional()
    .trim()
    .notEmpty()
    .withMessage("title cannot be empty")
    .isLength({ max: 500 })
    .withMessage("Title must be at most 500 characters"),
  body("description")
    .optional({ nullable: true })
    .isString()
    .withMessage("description must be a string"),
  body("price")
    .optional()
    .isFloat({ min: 0 })
    .withMessage("price must be a number >= 0"),
  body("category_id")
    .optional({ nullable: true })
    .isUUID()
    .withMessage("category_id must be a valid UUID"),
  body("variants")
    .optional({ nullable: true })
    .isArray()
    .withMessage("variants must be an array"),
];

module.exports = {
  listQueryValidation,
  uuidParam,
  createProductValidation,
  updateProductValidation,
};
