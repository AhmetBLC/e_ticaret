const path = require("path");
const fs = require("fs");
const express = require("express");
const cors = require("cors");
const swaggerUi = require("swagger-ui-express");
const apiRoutes = require("./routes");
const notFound = require("./middlewares/notFound");
const errorHandler = require("./middlewares/errorHandler");
const bodyParserErrorHandler = require("./middlewares/bodyParserErrorHandler");
const { requestLogger } = require("./middlewares/requestLogger");
const { corsOrigin } = require("./config/env");

let openApiDocument = null;
try {
  openApiDocument = JSON.parse(
    fs.readFileSync(path.join(__dirname, "docs", "openapi.json"), "utf8")
  );
} catch {
  // openapi.json may not exist yet — Swagger UI will be unavailable
}

const app = express();

app.use(
  cors({
    origin: corsOrigin === "*" ? true : corsOrigin,
    credentials: true,
  })
);
app.use("/public", express.static(path.join(process.cwd(), "public")));
app.use(express.json({ limit: "1mb" }));
app.use(bodyParserErrorHandler);

if (openApiDocument) {
  app.get("/api-docs.json", (req, res) => {
    res.json(openApiDocument);
  });

  app.use(
    "/api-docs",
    swaggerUi.serve,
    swaggerUi.setup(openApiDocument, {
      customSiteTitle: "E-Ticaret API — Swagger UI",
      swaggerOptions: {
        persistAuthorization: true,
        docExpansion: "list",
        filter: true,
        tryItOutEnabled: true,
      },
    })
  );
}

app.use("/api", requestLogger);
app.use("/api", apiRoutes);
app.use(notFound);
app.use(errorHandler);

module.exports = app;
