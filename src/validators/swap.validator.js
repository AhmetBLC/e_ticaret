const { body, param, query } = require("express-validator");
const { SWAP_STATUS } = require("../constants/swapStatus");

const swapListQueryValidation = [
  query("page")
    .optional()
    .isInt({ min: 1 })
    .withMessage("page must be a positive integer"),
  query("limit")
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage("limit must be between 1 and 100"),
  query("status")
    .optional()
    .isIn(Object.values(SWAP_STATUS))
    .withMessage("status must be a valid swap status"),
];

const createSwapValidation = [
  body("product_offered_id")
    .isUUID()
    .withMessage("product_offered_id must be a valid UUID"),
  body("product_requested_id")
    .isUUID()
    .withMessage("product_requested_id must be a valid UUID"),
];

const swapIdParam = [
  param("id").isUUID().withMessage("Invalid swap id"),
];

module.exports = {
  swapListQueryValidation,
  createSwapValidation,
  swapIdParam,
};
