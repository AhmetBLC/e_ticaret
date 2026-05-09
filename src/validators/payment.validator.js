const { body, param } = require("express-validator");

const paymentIdParam = [
  param("id").isUUID().withMessage("Invalid payment id"),
];

const initiatePaymentValidation = [
  body("amount")
    .isFloat({ min: 0.01 })
    .withMessage("Amount must be > 0"),
  body("order_id").optional({ nullable: true }).isUUID(),
  body("swap_id").optional({ nullable: true }).isUUID(),
  body("currency").optional().isIn(["TRY", "USD", "EUR"]),
  body("card_last_four")
    .optional()
    .isLength({ min: 4, max: 4 })
    .withMessage("card_last_four must be 4 digits"),
  body("card_brand").optional().isString(),
  body("require_3ds").optional().isBoolean(),
];

module.exports = { paymentIdParam, initiatePaymentValidation };
