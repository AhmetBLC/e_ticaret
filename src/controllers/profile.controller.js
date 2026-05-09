function getProfile(req, res) {
  res.json({
    success: true,
    data: {
      user: req.user,
    },
  });
}

module.exports = {
  getProfile,
};
