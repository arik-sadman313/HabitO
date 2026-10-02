from pydantic import BaseModel, EmailStr
from uuid import UUID
from datetime import datetime
from typing import Optional

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    display_name: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"

class UserResponse(BaseModel):
    id: UUID
    email: str
    display_name: str
    timezone: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class TokenRefresh(BaseModel):
    refresh_token: str

class ProfileUpdateRequest(BaseModel):
    display_name: Optional[str] = None
    timezone: Optional[str] = None

class PasswordChangeRequest(BaseModel):
    current_password: str
    new_password: str
