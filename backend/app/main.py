from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.routes import auth, sync, couples

app = FastAPI(title="HabitO Backend API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(sync.router, prefix="/api/v1/sync", tags=["sync"])
app.include_router(couples.router, prefix="/api/v1/couples", tags=["couples"])

@app.get("/api/v1/health")
async def health_check():
    return {"status": "ok"}
