from pydantic import BaseModel


class Product(BaseModel):
    id: str
    name: str
    price: str
    category: str
    created_at: str


class CreateProductRequest(BaseModel):
    name: str
    price: float
    category: str
