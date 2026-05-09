const { query } = require("./src/config/database");

async function fix() {
  try {
    console.log("Making price_override nullable...");
    await query("ALTER TABLE product_variants ALTER COLUMN price_override DROP NOT NULL");
    console.log("Success.");
  } catch (err) {
    console.error("Migration failed:", err);
  } finally {
    process.exit();
  }
}

fix();
