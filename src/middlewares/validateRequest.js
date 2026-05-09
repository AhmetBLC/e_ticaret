const { validationResult } = require("express-validator");

function validateRequest(req, res, next) {
  const result = validationResult(req);
  if (result.isEmpty()) {
    return next();
  }

  const details = result.array().map((e) => ({
    field: e.path,
    message: e.msg,
  }));

  const firstMsg = details[0]?.message || "Validation failed";

  return res.status(400).json({
    success: false,
    error: {
      code: "VALIDATION_ERROR",
      message: firstMsg,
      details,
    },
  });
}

module.exports = validateRequest;
