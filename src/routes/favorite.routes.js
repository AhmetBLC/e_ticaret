const express = require("express");
const favoriteController = require("../controllers/favorite.controller");
const { authenticate } = require("../middlewares/auth.middleware");

const router = express.Router();

router.use(authenticate);

router.get("/", favoriteController.getMyFavorites);
router.post("/toggle/:productId", favoriteController.toggleFavorite);

module.exports = router;
