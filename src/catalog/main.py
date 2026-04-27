from fastapi import FastAPI
app = FastAPI(title="Product Catalog")
@app.get("/health")
def health():
return {"status": "healthy", "service": "product-catalog"}
@app.get("/products/{product_id}")
def get_product(product_id: str):
return {"id": product_id, "name": "sample product", "price": 19.99} 
