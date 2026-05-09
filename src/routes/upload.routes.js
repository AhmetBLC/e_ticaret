const express = require("express");
const upload = require("../middlewares/upload.middleware");
const { authenticate } = require("../middlewares/auth.middleware");
const asyncHandler = require("../middlewares/asyncHandler");

const router = express.Router();

router.post(
  "/",
  authenticate,
  upload.single("image"),
  asyncHandler(async (req, res) => {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        code: "VALIDATION_ERROR",
        message: "No image uploaded",
      });
    }

    // Construct the full URL
    const baseUrl = `${req.protocol}://${req.get("host")}`;
    const fileUrl = `${baseUrl}/public/uploads/${req.file.filename}`;

    res.status(201).json({
      success: true,
      data: {
        url: fileUrl,
      },
    });
  })
);

module.exports = router;
