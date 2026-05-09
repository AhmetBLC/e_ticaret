const { query } = require("./src/config/database");

async function migrate() {
  try {
    console.log("Migrating product_variants table...");
    
    // Check if price column exists to avoid error on double run
    const r = await query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'product_variants' AND column_name = 'price'
    `);

    if (r.rows.length > 0) {
      await query("ALTER TABLE product_variants RENAME COLUMN price TO price_override");
      await query("ALTER TABLE product_variants RENAME COLUMN stock TO stock_quantity");
      await query("ALTER TABLE product_variants DROP COLUMN IF EXISTS value");
      console.log("Migration successful: Renamed columns and dropped 'value'.");
    } else {
      console.log("Columns already migrated or table structure is different.");
    }
  } catch (err) {
    console.error("Migration failed:", err);
  } finally {
    process.exit();
  }
}

migrate();
