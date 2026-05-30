import { FastifyInstance } from "fastify";

export async function healthRoutes(app: FastifyInstance) {
  app.get("/health", async (request, reply) => {
    return {
      status: "healthy",
      service: "api-gateway",
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      version: process.env.APP_VERSION || "1.0.0",
    };
  });

  app.get("/ready", async (request, reply) => {
    // Readiness check — verify downstream services are reachable
    // In production, this would ping order-service and product-catalog
    return { status: "ready" };
  });
}
