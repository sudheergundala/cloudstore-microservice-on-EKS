from fastapi import APIRouter
from fastapi.responses import JSONResponse

router = APIRouter()


@router.get("/health")
def health_check():
    return {"status": "healthy", "service": "product-catalog"}


@router.get("/ready")
def readiness_check():
    # Import here to avoid circular imports
    from main import clients

    # Check if DynamoDB and Redis are reachable
    try:
        clients["dynamodb"].ping()
        clients["cache"].ping()
        return {"status": "ready"}
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={"status": "not ready", "reason": str(e)},
        )
