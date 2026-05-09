function getHealth(req, res) {
  res.json({
    success: true,
    data: {
      status: "ok",
      timestamp: new Date().toISOString(),
    },
  });
}

module.exports = {
  getHealth,
};
