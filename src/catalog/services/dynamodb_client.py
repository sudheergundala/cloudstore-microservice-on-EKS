import boto3
import uuid
from datetime import datetime, timezone


class DynamoDBClient:
    def __init__(self, endpoint_url, table_name, region):
        # endpoint_url is set for local dev (DynamoDB Local)
        # In production it's None, so boto3 uses real AWS DynamoDB
        self.dynamodb = boto3.resource(
            "dynamodb",
            endpoint_url=endpoint_url,
            region_name=region,
        )
        self.table_name = table_name
        self.table = self.dynamodb.Table(table_name)

    def ensure_table(self):
        # Create the table if it doesn't exist (for local dev)
        existing = [t.name for t in self.dynamodb.tables.all()]
        if self.table_name not in existing:
            self.dynamodb.create_table(
                TableName=self.table_name,
                KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
                AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
                BillingMode="PAY_PER_REQUEST",
            )
            self.table = self.dynamodb.Table(self.table_name)

    def get_product(self, product_id):
        response = self.table.get_item(Key={"id": product_id})
        return response.get("Item")

    def list_products(self):
        response = self.table.scan(Limit=50)
        return response.get("Items", [])

    def create_product(self, req):
        product = {
            "id": str(uuid.uuid4()),
            "name": req.name,
            "price": str(req.price),
            "category": req.category,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }
        self.table.put_item(Item=product)
        return product

    def ping(self):
        # Used by readiness check
        self.dynamodb.meta.client.list_tables(Limit=1)
