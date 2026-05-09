const express = require("express");
const asyncHandler = require("../middlewares/asyncHandler");
const { authenticate, requireRole } = require("../middlewares/auth.middleware");
const { ROLES } = require("../constants/roles");
const adminController = require("../controllers/admin.controller");
const costingController = require("../controllers/costing.controller");

const router = express.Router();

// All admin routes require authentication + admin role
router.use(authenticate, requireRole(ROLES.ADMIN));

router.get("/dashboard", asyncHandler(adminController.dashboard));
router.get("/users", asyncHandler(adminController.listUsers));
router.get("/swaps", asyncHandler(adminController.listSwaps));
router.get("/products", asyncHandler(adminController.listProducts));
router.get("/orders", asyncHandler(adminController.listOrders));
router.get("/reports/finance", asyncHandler(costingController.getWorkshopReport));

module.exports = router;
