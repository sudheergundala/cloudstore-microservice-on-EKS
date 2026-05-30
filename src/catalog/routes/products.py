import logging
from fastapi import APIRouter, HTTPException
from models.product import Product, CreateProductRequest

router = APIRouter()
logger = logging.getLogger("product-catalog")


@router.get("/{product_id}")
def get_product(product_id: str):
    from main import clients
    cache = clients["cache"]
    dynamodb = clients["dynamodb"]

    # CACHE-ASIDE PATTERN:
    # 1. Check cache first
    cached = cache.get(f"product:{product_id}")
    if cached:
        logger.info(f"Cache HIT for product {product_id}")
        return cached

    # 2. Cache miss — get from DynamoDB
    logger.info(f"Cache MISS for product {product_id}")
    product = dynamodb.get_product(product_id)
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    # 3. Store in cache for next time (5 minute TTL)
    cache.set(f"product:{product_id}", product, ttl=300)
    return product


@router.get("")
def list_products():
    from main import clients
    return clients["dynamodb"].list_products()


@router.post("")
def create_product(req: CreateProductRequest):
    from main import clients
    dynamodb = clients["dynamodb"]
    cache = clients["cache"]

    product = dynamodb.create_product(req)

    # Invalidate cache so the new product appears
    cache.delete(f"product:{product['id']}")

    logger.info(f"Created product {product['id']}")
    return product
