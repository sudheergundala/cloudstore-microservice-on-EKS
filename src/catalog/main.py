import os
import logging
import sys
from contextlib import asynccontextmanager
from fastapi import FastAPI
from routes import health, products
from services.dynamodb_client import DynamoDBClient
from services.cache_client import CacheClient

# Structured JSON logging
logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format='{"time":"%(asctime)s","level":"%(levelname)s","message":"%(message)s"}',
    stream=sys.stdout,
)
logger = logging.getLogger("product-catalog")

# Shared clients (initialized at startup)
clients = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: initialize connections
    logger.info("Starting product catalog service")
    clients["dynamodb"] = DynamoDBClient(
        endpoint_url=os.getenv("DYNAMODB_ENDPOINT"),
        table_name=os.getenv("DYNAMODB_TABLE", "products"),
        region=os.getenv("AWS_REGION", "us-east-1"),
    )
    clients["cache"] = CacheClient(
        redis_url=os.getenv("REDIS_URL", "redis://localhost:6379"),
    )
    clients["dynamodb"].ensure_table()
    logger.info("Product catalog ready")

    yield  # application runs here

    # Shutdown: clean up connections
    logger.info("Shutting down product catalog service")
    clients["cache"].close()


app = FastAPI(title="Product Catalog", lifespan=lifespan)

# Register routes
app.include_router(health.router)
app.include_router(products.router, prefix="/products")


# Make clients available to routes
def get_dynamodb():
    return clients["dynamodb"]


def get_cache():
    return clients["cache"]
