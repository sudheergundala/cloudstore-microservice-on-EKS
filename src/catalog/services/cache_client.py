import json
import redis


class CacheClient:
    def __init__(self, redis_url):
        self.client = redis.from_url(redis_url, decode_responses=True)

    def get(self, key):
        value = self.client.get(key)
        return json.loads(value) if value else None

    def set(self, key, value, ttl=300):
        self.client.setex(key, ttl, json.dumps(value))

    def delete(self, key):
        self.client.delete(key)

    def ping(self):
        self.client.ping()

    def close(self):
        self.client.close()
