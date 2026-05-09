const { query } = require("./src/config/database");

async function check() {
  try {
    const r = await query(`
      SELECT column_name, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'product_variants'
    `);
    console.log("Columns in product_variants:");
    r.rows.forEach(row => console.log(`- ${row.column_name} (Nullable: ${row.is_nullable})`));
  } catch (err) {
    console.error(err);
  } finally {
    process.exit();
  }
}

check();
