const { param, query } = require("express-validator");

const listQueryValidation = [
  query("page")
    .optional()
    .isInt({ min: 1 })
    .withMessage("page must be a positive integer"),
  query("limit")
    .optional()
    .isInt({ min: 1, max: 500 })
    .withMessage("limit must be between 1 and 500"),
];

const workOrderIdParam = [
  param("id").isUUID().withMessage("Invalid work order id"),
];

module.exports = {
  listQueryValidation,
  workOrderIdParam,
};
