/**
 * Handles errors from `express.json()` / body-parser (invalid JSON, payload too large).
 * Must be registered immediately after `express.json()`.
 */
function bodyParserErrorHandler(err, req, res, next) {
  if (err instanceof SyntaxError && err.status === 400 && "body" in err) {
    return res.status(400).json({
      success: false,
      error: {
        code: "INVALID_JSON",
        message: "Request body must be valid JSON",
      },
    });
  }

  if (err.type === "entity.too.large") {
    return res.status(413).json({
      success: false,
      error: {
        code: "PAYLOAD_TOO_LARGE",
        message: "Request body exceeds the allowed size limit",
      },
    });
  }

  return next(err);
}

module.exports = bodyParserErrorHandler;
