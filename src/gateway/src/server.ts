import fastify from "fastify";
import cors from "@fastify/cors";
import helmet from "@fastify/helmet";
import { healthRoutes } from "./routes/health";
import { productRoutes } from "./routes/products";
import { orderRoutes } from "./routes/orders";

const app = fastify({
  logger: {
    level: process.env.LOG_LEVEL || "info",
  },
});

// Middleware
app.register(cors);
app.register(helmet);

// Routes
app.register(healthRoutes);
app.register(productRoutes, { prefix: "/api/v1" });
app.register(orderRoutes, { prefix: "/api/v1" });

// Start server
const PORT = parseInt(process.env.PORT || "3000");
const HOST = process.env.HOST || "0.0.0.0";

const start = async () => {
  try {
    await app.listen({ port: PORT, host: HOST });
    app.log.info(`API Gateway running on ${HOST}:${PORT}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
};

// Graceful shutdown
const shutdown = async (signal: string) => {
  app.log.info(`Received ${signal}. Shutting down gracefully...`);
  await app.close();
  process.exit(0);
};

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));

start();
