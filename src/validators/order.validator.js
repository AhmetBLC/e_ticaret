const { body, query, param } = require("express-validator");
const { ORDER_STATUS } = require("../constants/orderStatus");

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

const createOrderValidation = [
  body("items")
    .isArray({ min: 1 })
    .withMessage("items must be a non-empty array"),
  body("items.*.variant_id")
    .isUUID()
    .withMessage("each item.variant_id must be a valid UUID"),
  body("items.*.quantity")
    .isInt({ min: 1 })
    .withMessage("each item.quantity must be a positive integer"),
];

const orderIdParam = [
  param("id").isUUID().withMessage("Invalid order id"),
];

const advanceOrderStatusValidation = [
  body("status")
    .isIn([ORDER_STATUS.SHIPPED, ORDER_STATUS.DELIVERED])
    .withMessage("status must be SHIPPED or DELIVERED"),
];

module.exports = {
  listQueryValidation,
  createOrderValidation,
  orderIdParam,
  advanceOrderStatusValidation,
};
