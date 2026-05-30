import { FastifyInstance } from "fastify";
import { randomUUID } from "crypto";

export async function requestLogger(app: FastifyInstance) {
  app.addHook("onRequest", async (request) => {
    // Add correlation ID for distributed tracing
    request.headers["x-request-id"] = 
      request.headers["x-request-id"] || randomUUID();
  });

  app.addHook("onResponse", async (request, reply) => {
    request.log.info({
      method: request.method,
      url: request.url,
      statusCode: reply.statusCode,
      responseTime: reply.elapsedTime,
      requestId: request.headers["x-request-id"],
    });
  });
}
