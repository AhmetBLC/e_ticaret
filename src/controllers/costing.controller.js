const workOrderModel = require("../models/workOrder.model");

async function getWorkshopReport(req, res) {
  const data = await workOrderModel.getFinancialReport();
  res.json({ success: true, data });
}

module.exports = {
  getWorkshopReport,
};
