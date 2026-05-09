const { query, withTransaction } = require("./src/config/database");

async function fix() {
  try {
    console.log("Starting data fix for missing variants...");
    
    // Find products that have NO variants
    const res = await query(`
      SELECT p.id, p.price, p.title 
      FROM products p
      LEFT JOIN product_variants pv ON p.id = pv.product_id
      WHERE pv.id IS NULL
    `);
    
    console.log(`Found ${res.rows.length} products without variants.`);
    
    if (res.rows.length === 0) {
      console.log("No products need fixing.");
      process.exit(0);
    }

    await withTransaction(async (client) => {
      for (const product of res.rows) {
        console.log(`Fixing Product: ${product.title} (${product.id})`);
        
        await client.query(
          "INSERT INTO product_variants (product_id, name, value, price, stock) VALUES ($1, $2, $3, $4, $5)",
          [product.id, "Base", "Default", product.price, 1]
        );
      }
    });

    console.log("Data fix completed successfully.");
    process.exit(0);
  } catch (err) {
    console.error("Data fix failed:", err);
    process.exit(1);
  }
}

fix();
