const express = require("express");
const rmaController = require("../controllers/rma.controller");
const { authenticate } = require("../middlewares/auth.middleware");
const asyncHandler = require("../middlewares/asyncHandler");

const router = express.Router();

router.use(authenticate);

router.post("/", asyncHandler(rmaController.requestReturn));
router.get("/my", asyncHandler(rmaController.getMyReturns));
router.get("/all", asyncHandler(rmaController.getAllReturns));
router.patch("/:id", asyncHandler(rmaController.updateStatus));

module.exports = router;
