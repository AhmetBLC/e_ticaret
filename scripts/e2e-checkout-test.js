/**
 * E2E test for new modules: Address, Payment (Iyzico/Stripe sim), Shipment (Cargo), Checkout.
 * Run with: node scripts/e2e-checkout-test.js
 * Prerequisite: server running on http://localhost:3000
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
    if (token) options.headers["Authorization"] = `Bearer ${token}`;
    const req = http.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
        catch { resolve({ status: res.statusCode, body: data }); }
      });
    });
    req.on("error", reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

function assert(condition, msg) {
  if (!condition) throw new Error(`ASSERTION FAILED: ${msg}`);
}
function log(step, msg) {
  console.log(`\n✅ [${step}] ${msg}`);
}

(async () => {
  try {
    console.log("🛒 Starting E2E Checkout & Payment Test\n");
    console.log("=".repeat(55));

    // 1. Register buyer
    const ts = Date.now();
    const regBuyer = await request("POST", "/auth/register", {
      email: `buyer_${ts}@test.com`, password: "test12345",
    });
    assert(regBuyer.body.success, `Register buyer failed: ${JSON.stringify(regBuyer.body)}`);
    const buyerId = regBuyer.body.data.user.id;
    log("1", `Buyer registered: ${buyerId}`);

    // 2. Register seller
    const regSeller = await request("POST", "/auth/register", {
      email: `seller_${ts}@test.com`, password: "test12345",
    });
    assert(regSeller.body.success, `Register seller failed`);
    const sellerId = regSeller.body.data.user.id;
    log("2", `Seller registered: ${sellerId}`);

    // 3. Login both
    const loginBuyer = await request("POST", "/auth/login", {
      email: `buyer_${ts}@test.com`, password: "test12345",
    });
    const tokenBuyer = loginBuyer.body.data.token;
    const loginSeller = await request("POST", "/auth/login", {
      email: `seller_${ts}@test.com`, password: "test12345",
    });
    const tokenSeller = loginSeller.body.data.token;
    log("3", "Both users logged in");

    // 4. Seller creates a product
    const prodRes = await request("POST", "/products", {
      title: "MacBook Air M3",
      description: "2024 model, space gray, kutulu",
      price: 45000,
      variants: [
        { name: "RAM", value: "16GB", price: 45000, stock: 5 },
        { name: "RAM", value: "24GB", price: 55000, stock: 3 },
      ],
    }, tokenSeller);
    assert(prodRes.body.success, `Product creation failed: ${JSON.stringify(prodRes.body)}`);
    const product = prodRes.body.data.product;
    const variant16 = product.variants.find(v => v.value === "16GB");
    const variant24 = product.variants.find(v => v.value === "24GB");
    log("4", `Product created: ${product.id} with ${product.variants.length} variants`);

    // ─────────────── ADDRESS MODULE ───────────────

    // 5. Buyer adds address
    const addrRes = await request("POST", "/addresses", {
      full_name: "Ahmet Balcı",
      phone: "05551234567",
      address_line1: "Atatürk Cad. No:42",
      address_line2: "Daire 5",
      city: "İstanbul",
      district: "Kadıköy",
      postal_code: "34710",
      label: "Ev",
      is_default: true,
    }, tokenBuyer);
    assert(addrRes.body.success, `Address creation failed: ${JSON.stringify(addrRes.body)}`);
    const addressId = addrRes.body.data.address.id;
    assert(addrRes.body.data.address.is_default === true, "Address should be default");
    log("5", `Address created: ${addressId} (${addrRes.body.data.address.city})`);

    // 6. List addresses
    const addrList = await request("GET", "/addresses", null, tokenBuyer);
    assert(addrList.body.success, "Address list failed");
    assert(addrList.body.data.addresses.length >= 1, "Should have at least 1 address");
    log("6", `Addresses listed: ${addrList.body.data.addresses.length}`);

    // ─────────────── ONE-PAGE CHECKOUT ───────────────

    // 7. Buyer does one-page checkout
    const checkoutRes = await request("POST", "/checkout", {
      items: [{ variant_id: variant16.id, quantity: 1 }],
      shipping_address_id: addressId,
      card_last_four: "4242",
      card_brand: "Visa",
      skip_3ds: false,
    }, tokenBuyer);
    assert(checkoutRes.body.success, `Checkout failed: ${JSON.stringify(checkoutRes.body)}`);
    const { order, payment, shipment } = checkoutRes.body.data;
    assert(order, "Order should exist");
    assert(payment, "Payment should exist");
    assert(shipment, "Shipment should exist");
    log("7", `Checkout complete!
    → Order:    ${order.id} (${order.status})
    → Payment:  ${payment.id} (${payment.status}) | ${payment.card_brand} ****${payment.card_last_four} | ₺${payment.amount}
    → Shipment: ${shipment.id} (${shipment.status}) | Tracking: ${shipment.tracking_number} | Barcode: ${shipment.barcode}`);

    // ─────────────── PAYMENT: 3D SECURE ───────────────

    // 8. Payment should be AWAITING_3DS
    assert(payment.status === "AWAITING_3DS", `Payment should be AWAITING_3DS, got ${payment.status}`);
    assert(payment.three_ds_url, "Should have 3DS redirect URL");
    log("8", `3D Secure URL: ${payment.three_ds_url}`);

    // 9. Complete 3DS verification -> Payment should be HELD in escrow pool
    const verify3ds = await request("POST", `/payments/${payment.id}/verify-3ds`);
    assert(verify3ds.body.success, `3DS verify failed: ${JSON.stringify(verify3ds.body)}`);
    assert(verify3ds.body.data.payment.status === "HELD", "Payment should be HELD after 3DS for orders");
    log("9", `3D Secure verified → Payment HELD in Escrow ✓`);

    // 10. Check payment history
    const payHist = await request("GET", "/payments/history", null, tokenBuyer);
    assert(payHist.body.success, "Payment history failed");
    assert(payHist.body.data.payments.length >= 1, "Should have at least 1 payment");
    log("10", `Payment history: ${payHist.body.data.payments.length} payment(s)`);

    // ─────────────── CARGO / SHIPMENT ───────────────

    // 11. Track shipment (public)
    const trackRes = await request("GET", `/shipments/track/${shipment.tracking_number}`);
    assert(trackRes.body.success, `Tracking failed: ${JSON.stringify(trackRes.body)}`);
    assert(trackRes.body.data.shipment.status === "LABEL_CREATED", "Should be LABEL_CREATED");
    log("11", `Tracking lookup OK: ${trackRes.body.data.shipment.tracking_number} → ${trackRes.body.data.shipment.status}`);

    // 12. Advance shipment: LABEL_CREATED → PICKED_UP
    const adv1 = await request("PATCH", `/shipments/${shipment.id}/status`, {
      status: "PICKED_UP",
    }, tokenSeller);
    assert(adv1.body.success, `Advance to PICKED_UP failed`);
    assert(adv1.body.data.shipment.status === "PICKED_UP", "Should be PICKED_UP");
    log("12", "Shipment → PICKED_UP");

    // 13. Advance: PICKED_UP → IN_TRANSIT
    const adv2 = await request("PATCH", `/shipments/${shipment.id}/status`, {
      status: "IN_TRANSIT",
    }, tokenSeller);
    assert(adv2.body.success, "Advance to IN_TRANSIT failed");
    log("13", "Shipment → IN_TRANSIT");

    // 14. Simulate full delivery
    const simDel = await request("POST", `/shipments/${shipment.id}/simulate-delivery`, null, tokenSeller);
    assert(simDel.body.success, "Simulate delivery failed");
    assert(simDel.body.data.shipment.status === "DELIVERED", "Should be DELIVERED");
    log("14", "Shipment → DELIVERED (simulated full delivery) ✓");
    
    // 14b. Set Buyer as admin and approve the order in the workshop
    const { query: dbQ } = require("../src/config/database");
    await dbQ("UPDATE users SET role = 'admin' WHERE id = $1", [buyerId]);
    log("14b", "Buyer promoted to admin");
    
    // Admin lists work orders to find this order
    const adminOrdersRes = await request("GET", "/workorders", null, tokenBuyer);
    assert(adminOrdersRes.body.success, "Work order list failed");
    const wo = adminOrdersRes.body.data.work_orders.find(w => w.order_id === order.id);
    assert(wo, "Work order for the purchase not found");
    
    // Admin approves the work order
    const appWo = await request("PUT", `/workorders/${wo.id}/approve`, null, tokenBuyer);
    assert(appWo.body.success, "Approve work order failed");
    
    const payHistory = await request("GET", `/payments/${payment.id}`, null, tokenBuyer);
    assert(payHistory.body.data.payment.status === "RELEASED", "Payment should be RELEASED");
    log("14c", "Workshop APPROVED → Payment RELEASED to seller ✓");

    // 15. List my shipments
    const myShipments = await request("GET", "/shipments", null, tokenBuyer);
    assert(myShipments.body.success, "My shipments list failed");
    assert(myShipments.body.data.shipments.length >= 1, "Should have at least 1 shipment");
    log("15", `My shipments: ${myShipments.body.data.shipments.length}`);

    // ─────────────── STANDALONE PAYMENT ───────────────

    // 16. Direct payment (no checkout)
    const directPay = await request("POST", "/payments", {
      amount: 150,
      card_last_four: "1234",
      card_brand: "Mastercard",
      require_3ds: false,
    }, tokenBuyer);
    assert(directPay.body.success, `Direct payment failed: ${JSON.stringify(directPay.body)}`);
    assert(directPay.body.data.payment.status === "PAID", "Direct pay should be PAID (no 3DS)");
    log("16", `Direct payment: ₺${directPay.body.data.payment.amount} → PAID (no 3DS)`);

    // 17. Payment detail
    const payDetail = await request("GET", `/payments/${directPay.body.data.payment.id}`, null, tokenBuyer);
    assert(payDetail.body.success, "Payment detail failed");
    assert(payDetail.body.data.payment.provider_ref, "Should have provider ref");
    log("17", `Payment detail: provider_ref=${payDetail.body.data.payment.provider_ref}`);

    // ─────────────── ADDRESS UPDATE/DELETE ───────────────

    // 18. Update address
    const addrUpd = await request("PUT", `/addresses/${addressId}`, {
      full_name: "Ahmet B.",
      city: "Ankara",
    }, tokenBuyer);
    assert(addrUpd.body.success, "Address update failed");
    assert(addrUpd.body.data.address.city === "Ankara", "City should be Ankara");
    log("18", `Address updated: city → Ankara`);

    // 19. Variant price check
    const prodDetail = await request("GET", `/products/${product.id}`);
    const v24 = prodDetail.body.data.product.variants.find(v => v.value === "24GB");
    assert(Number(v24.price) === 55000, "24GB variant should be ₺55000");
    log("19", `Variant pricing: 16GB=₺${variant16.price}, 24GB=₺${v24.price}`);

    // 20. Categories
    const catRes = await request("GET", "/categories");
    assert(catRes.body.success, "Categories failed");
    log("20", `Categories: ${catRes.body.data.categories.length} total`);

    console.log("\n" + "=".repeat(55));
    console.log("🎉 ALL 20 TESTS PASSED — Checkout, Payment & Cargo Verified!");
    console.log("=".repeat(55));
    process.exit(0);
  } catch (err) {
    console.error("\n❌ TEST FAILED:", err.message);
    process.exit(1);
  }
})();
