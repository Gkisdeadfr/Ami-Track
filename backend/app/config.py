from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    portal_base: str = "https://s.amizone.net"
    nexacad_base: str = "https://nexacad.pages.dev"
    token_secret: str = "development-only-change-this-secret"
    session_ttl_minutes: int = 720
    allowed_origins: str = "http://localhost:3000"

    model_config = SettingsConfigDict(env_prefix="AMITRACK_", env_file=".env", extra="ignore")

settings = Settings()
