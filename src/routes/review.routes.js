const express = require("express");
const reviewController = require("../controllers/review.controller");
const { authenticate } = require("../middlewares/auth.middleware");
const asyncHandler = require("../middlewares/asyncHandler");

const router = express.Router();

router.get("/:productId", asyncHandler(reviewController.getProductReviews));
router.post("/:productId", authenticate, asyncHandler(reviewController.addReview));

module.exports = router;
