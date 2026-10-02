from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+psycopg://habito:habito_password@localhost:5432/habito_dev"
    SECRET_KEY: str = "supersecretkey_for_development_only_12345"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    
    model_config = SettingsConfigDict(env_file=".env")

settings = Settings()
