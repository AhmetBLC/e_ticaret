const express = require("express");
const couponController = require("../controllers/coupon.controller");
const asyncHandler = require("../middlewares/asyncHandler");

const router = express.Router();

router.post("/validate", asyncHandler(couponController.validate));

module.exports = router;
