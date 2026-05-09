const { body } = require("express-validator");

const checkoutValidation = [
  body("items")
    .isArray({ min: 1 })
    .withMessage("items must be a non-empty array"),
  body("items.*.variant_id")
    .isUUID()
    .withMessage("Each item must have a valid variant_id"),
  body("items.*.quantity")
    .isInt({ min: 1 })
    .withMessage("Each item.quantity must be a positive integer"),
  body("shipping_address_id")
    .optional({ nullable: true })
    .isUUID()
    .withMessage("shipping_address_id must be a valid UUID"),
  body("card_last_four")
    .optional()
    .isLength({ min: 4, max: 4 }),
  body("card_brand").optional().isString(),
  body("skip_3ds").optional().isBoolean(),
];

module.exports = { checkoutValidation };
