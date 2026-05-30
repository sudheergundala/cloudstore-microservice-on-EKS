import { FastifyInstance } from "fastify";

const CATALOG_URL = process.env.PRODUCT_CATALOG_URL || "http://localhost:8000";

export async function productRoutes(app: FastifyInstance) {
  // GET /api/v1/products/:id
  app.get("/products/:id", async (request, reply) => {
    const { id } = request.params as { id: string };
    
    try {
      const response = await fetch(`${CATALOG_URL}/products/${id}`);
      
      if (!response.ok) {
        reply.code(response.status);
        return { error: "Product not found" };
      }
      
      return await response.json();
    } catch (err) {
      app.log.error({ err, productId: id }, "Failed to reach product catalog");
      reply.code(503);
      return { error: "Product catalog unavailable" };
    }
  });

  // GET /api/v1/products
  app.get("/products", async (request, reply) => {
    try {
      const response = await fetch(`${CATALOG_URL}/products`);
      return await response.json();
    } catch (err) {
      app.log.error({ err }, "Failed to reach product catalog");
      reply.code(503);
      return { error: "Product catalog unavailable" };
    }
  });
}
