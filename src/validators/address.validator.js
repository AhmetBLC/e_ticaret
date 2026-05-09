const { body, param } = require("express-validator");

const addressIdParam = [
  param("id").isUUID().withMessage("Invalid address id"),
];

const createAddressValidation = [
  body("full_name").trim().notEmpty().withMessage("Full name is required"),
  body("address_line1").trim().notEmpty().withMessage("Address line 1 is required"),
  body("city").trim().notEmpty().withMessage("City is required"),
  body("label").optional().trim().isLength({ max: 100 }),
  body("phone").optional({ nullable: true }).trim(),
  body("address_line2").optional({ nullable: true }).trim(),
  body("district").optional({ nullable: true }).trim(),
  body("postal_code").optional({ nullable: true }).trim(),
  body("country").optional().trim(),
  body("is_default").optional().isBoolean(),
];

const updateAddressValidation = [
  ...addressIdParam,
  body("full_name").optional().trim().notEmpty(),
  body("address_line1").optional().trim().notEmpty(),
  body("city").optional().trim().notEmpty(),
  body("label").optional().trim(),
  body("phone").optional({ nullable: true }).trim(),
  body("address_line2").optional({ nullable: true }).trim(),
  body("district").optional({ nullable: true }).trim(),
  body("postal_code").optional({ nullable: true }).trim(),
  body("country").optional().trim(),
  body("is_default").optional().isBoolean(),
];

module.exports = { addressIdParam, createAddressValidation, updateAddressValidation };
