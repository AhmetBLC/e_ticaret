const express = require("express");
const imageController = require("../controllers/image.controller");
const { authenticate } = require("../middlewares/auth.middleware");
const asyncHandler = require("../middlewares/asyncHandler");

const router = express.Router();

router.get("/:productId", asyncHandler(imageController.getImages));
router.post("/:productId", authenticate, asyncHandler(imageController.addImage));
router.delete("/:imageId", authenticate, asyncHandler(imageController.deleteImage));

module.exports = router;
