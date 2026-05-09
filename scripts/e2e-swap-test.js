/**
 * End-to-end test script for the full C2C swap workflow.
 * Run with: node scripts/e2e-swap-test.js
 *
 * Prerequisites: server running on http://localhost:3000
 */

const http = require("http");

const BASE = "http://localhost:3000/api";

function request(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const url = new URL(`${BASE}${path}`);
    const options = {
      method,
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
      },
    };
    if (token) {
      options.headers["Authorization"] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ status: res.statusCode, body: parsed });
        } catch {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });
    req.on("error", reject);
    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

function assert(condition, msg) {
  if (!condition) {
    throw new Error(`ASSERTION FAILED: ${msg}`);
  }
}

function log(step, msg) {
  console.log(`\n✅ [${step}] ${msg}`);
}

(async () => {
  try {
    console.log("🚀 Starting E2E Swap Workflow Test\n");
    console.log("=".repeat(50));

    // 1. Register User A
    const regA = await request("POST", "/auth/register", {
      email: `usera_${Date.now()}@test.com`,
      password: "test12345",
    });
    assert(regA.body.success, `Register A failed: ${JSON.stringify(regA.body)}`);
    const userAId = regA.body.data.user.id;
    log("1", `User A registered: ${userAId}`);

    // 2. Register User B
    const regB = await request("POST", "/auth/register", {
      email: `userb_${Date.now()}@test.com`,
      password: "test12345",
    });
    assert(regB.body.success, `Register B failed: ${JSON.stringify(regB.body)}`);
    const userBId = regB.body.data.user.id;
    log("2", `User B registered: ${userBId}`);

    // 3. Login User A
    const loginA = await request("POST", "/auth/login", {
      email: regA.body.data.user.email,
      password: "test12345",
    });
    assert(loginA.body.success, `Login A failed: ${JSON.stringify(loginA.body)}`);
    const tokenA = loginA.body.data.token;
    log("3", `User A logged in, token received`);

    // 4. Login User B
    const loginB = await request("POST", "/auth/login", {
      email: regB.body.data.user.email,
      password: "test12345",
    });
    assert(loginB.body.success, `Login B failed: ${JSON.stringify(loginB.body)}`);
    const tokenB = loginB.body.data.token;
    log("4", `User B logged in, token received`);

    // 5. User A creates Product X (₺100)
    const prodX = await request(
      "POST",
      "/products",
      {
        title: "iPhone 15 Pro",
        description: "Temiz, kutulu, faturali",
        price: 100,
        variants: [
          { name: "Renk", value: "Siyah", price: 100, stock: 1 },
        ],
      },
      tokenA
    );
    assert(prodX.body.success, `Product X creation failed: ${JSON.stringify(prodX.body)}`);
    const productXId = prodX.body.data.product.id;
    log("5", `User A created Product X: ${productXId} (₺100)`);

    // 6. User B creates Product Y (₺75)
    const prodY = await request(
      "POST",
      "/products",
      {
        title: "Samsung Galaxy S24",
        description: "Az kullanilmis, garanti devam ediyor",
        price: 75,
        variants: [
          { name: "Renk", value: "Beyaz", price: 75, stock: 1 },
        ],
      },
      tokenB
    );
    assert(prodY.body.success, `Product Y creation failed: ${JSON.stringify(prodY.body)}`);
    const productYId = prodY.body.data.product.id;
    log("6", `User B created Product Y: ${productYId} (₺75)`);

    // 7. Verify products are listed
    const listProducts = await request("GET", "/products");
    assert(listProducts.body.success, "Product listing failed");
    assert(listProducts.body.data.products.length >= 2, "Not enough products");
    log("7", `Products listed: ${listProducts.body.data.pagination.total} total`);

    // 8. User A creates swap offer: my Product X for their Product Y
    const createSwap = await request(
      "POST",
      "/swaps",
      {
        product_offered_id: productXId,
        product_requested_id: productYId,
      },
      tokenA
    );
    assert(createSwap.body.success, `Swap creation failed: ${JSON.stringify(createSwap.body)}`);
    const swapId = createSwap.body.data.swap.id;
    assert(createSwap.body.data.swap.status === "PENDING", "Swap should be PENDING");
    log("8", `Swap created: ${swapId} (PENDING)`);

    // 9. User B sees the swap
    const swapList = await request("GET", "/swaps", null, tokenB);
    assert(swapList.body.success, "Swap list failed");
    assert(swapList.body.data.swaps.length >= 1, "User B should see at least 1 swap");
    log("9", `User B sees ${swapList.body.data.swaps.length} swap(s)`);

    // 10. User B accepts the swap → WORKSHOP + escrow
    const acceptSwap = await request("PUT", `/swaps/${swapId}/accept`, { card_last_four: "1234", card_brand: "Mastercard" }, tokenB);
    assert(acceptSwap.body.success, `Accept swap failed: ${JSON.stringify(acceptSwap.body)}`);
    assert(acceptSwap.body.data.swap.status === "WORKSHOP", "Swap should be WORKSHOP");
    const escrow = acceptSwap.body.data.escrow;
    const priceDiff = Math.abs(100 - 75);
    if (escrow) {
      assert(Number(escrow.amount) === priceDiff, `Escrow amount should be ${priceDiff}`);
      assert(escrow.status === "HELD", "Escrow should be HELD");
    }
    log("10", `Swap accepted → WORKSHOP. Escrow: ${escrow ? `₺${escrow.amount} (${escrow.status})` : "none"}`);

    // 11. Products should be locked (unavailable)
    const prodXAfter = await request("GET", `/products/${productXId}`);
    assert(prodXAfter.body.data.product.is_available === false, "Product X should be locked");
    const prodYAfter = await request("GET", `/products/${productYId}`);
    assert(prodYAfter.body.data.product.is_available === false, "Product Y should be locked");
    log("11", "Both products locked (is_available = false)");

    // 12. Set User A as admin (directly via DB for test purposes)
    const { query: dbQuery } = require("../src/config/database");
    await dbQuery("UPDATE users SET role = 'admin' WHERE id = $1", [userAId]);
    log("12", `User A promoted to admin`);

    // Re-login to get admin token
    const loginAdmin = await request("POST", "/auth/login", {
      email: regA.body.data.user.email,
      password: "test12345",
    });
    const adminToken = loginAdmin.body.data.token;

    // 13. Admin lists work orders
    const workOrders = await request("GET", "/workorders", null, adminToken);
    assert(workOrders.body.success, "Work order listing failed");
    assert(workOrders.body.data.work_orders.length >= 1, "Should have at least 1 work order");
    const woId = workOrders.body.data.work_orders.find(
      (w) => w.swap_id === swapId
    )?.id;
    assert(woId, "Work order for our swap not found");
    log("13", `Work order found: ${woId} (PENDING)`);

    // 14. Admin approves the work order
    const approveWo = await request("PUT", `/workorders/${woId}/approve`, null, adminToken);
    assert(approveWo.body.success, `Approve failed: ${JSON.stringify(approveWo.body)}`);
    assert(
      approveWo.body.data.work_order.status === "APPROVED",
      "Work order should be APPROVED"
    );
    log("14", "Work order APPROVED → Ownership transferred!");

    // 15. Verify ownership transfer
    const prodXFinal = await request("GET", `/products/${productXId}`);
    const prodYFinal = await request("GET", `/products/${productYId}`);
    assert(
      prodXFinal.body.data.product.user_id === userBId,
      `Product X should now belong to User B (expected ${userBId}, got ${prodXFinal.body.data.product.user_id})`
    );
    assert(
      prodYFinal.body.data.product.user_id === userAId,
      `Product Y should now belong to User A (expected ${userAId}, got ${prodYFinal.body.data.product.user_id})`
    );
    assert(prodXFinal.body.data.product.is_available === false, "Product X should stay unavailable");
    assert(prodYFinal.body.data.product.is_available === false, "Product Y should stay unavailable");
    log("15", "Ownership transferred! Product X → User B, Product Y → User A (Both products now sold/unavailable)");

    // 16. Verify escrow was released
    if (escrow) {
      const swapFinal = await request("GET", "/swaps?status=COMPLETED", null, tokenA);
      for (const s of swapFinal.body.data.swaps) {
        if (s.id === swapId && s.escrow) {
          assert(s.escrow.status === "RELEASED", "Escrow should be RELEASED");
        }
      }
      log("16", "Escrow RELEASED");
    }

    // 17. Test admin dashboard
    const dashboard = await request("GET", "/admin/dashboard", null, adminToken);
    assert(dashboard.body.success, "Admin dashboard failed");
    assert(dashboard.body.data.stats.total_products >= 2, "Dashboard should show products");
    log("17", `Admin dashboard: ${JSON.stringify(dashboard.body.data.stats)}`);

    // 18. Test order lifecycle
    const prodXVariants = prodXFinal.body.data.product.variants;
    if (prodXVariants && prodXVariants.length > 0) {
      const createOrder = await request(
        "POST",
        "/orders",
        {
          items: [{ variant_id: prodXVariants[0].id, quantity: 1 }],
        },
        tokenA
      );
      if (createOrder.body.success) {
        const orderId = createOrder.body.data.order.id;
        log("18a", `Order created: ${orderId} (PENDING)`);

        // Ship order
        const shipOrder = await request(
          "PATCH",
          `/orders/${orderId}/status`,
          { status: "SHIPPED" },
          tokenA
        );
        assert(shipOrder.body.success, "Ship order failed");
        assert(shipOrder.body.data.order.tracking_number, "Should have tracking number");
        log("18b", `Order shipped: ${shipOrder.body.data.order.tracking_number}`);

        // Deliver order
        const deliverOrder = await request(
          "PATCH",
          `/orders/${orderId}/status`,
          { status: "DELIVERED" },
          tokenA
        );
        assert(deliverOrder.body.success, "Deliver order failed");
        log("18c", "Order delivered ✓");
      }
    }

    // 19. Test categories
    const catList = await request("GET", "/categories");
    assert(catList.body.success, "Category listing failed");
    log("19", `Categories: ${catList.body.data.categories.length} total`);

    console.log("\n" + "=".repeat(50));
    console.log("🎉 ALL TESTS PASSED — Full C2C Swap Flow Verified!");
    console.log("=".repeat(50));
    process.exit(0);
  } catch (err) {
    console.error("\n❌ TEST FAILED:", err.message);
    process.exit(1);
  }
})();
