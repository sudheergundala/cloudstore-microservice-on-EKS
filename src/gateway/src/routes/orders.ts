import { FastifyInstance } from "fastify";

const ORDER_SERVICE_URL = process.env.ORDER_SERVICE_URL || "http://localhost:50051";

export async function orderRoutes(app: FastifyInstance) {
  // POST /api/v1/orders
  app.post("/orders", async (request, reply) => {
    const body = request.body as {
      productId: string;
      quantity: number;
    };

    // Basic validation
    if (!body.productId || !body.quantity) {
      reply.code(400);
      return { error: "productId and quantity are required" };
    }

    if (body.quantity <= 0 || body.quantity > 100) {
      reply.code(400);
      return { error: "quantity must be between 1 and 100" };
    }

    try {
      const response = await fetch(`${ORDER_SERVICE_URL}/orders`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });

      const data = await response.json();
      reply.code(response.status);
      return data;
    } catch (err) {
      app.log.error({ err }, "Failed to reach order service");
      reply.code(503);
      return { error: "Order service unavailable" };
    }
  });

  // GET /api/v1/orders/:id
  app.get("/orders/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    
    try {
      const response = await fetch(`${ORDER_SERVICE_URL}/orders/${id}`);
      const data = await response.json();
      reply.code(response.status);
      return data;
    } catch (err) {
      app.log.error({ err, orderId: id }, "Failed to reach order service");
      reply.code(503);
      return { error: "Order service unavailable" };
    }
  });
}
