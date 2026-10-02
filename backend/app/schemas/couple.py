from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict
from uuid import UUID

class CoupleMemberResponse(BaseModel):
    user_id: UUID
    role: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class CoupleResponse(BaseModel):
    id: UUID
    status: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class CoupleMeResponse(BaseModel):
    couple: Optional[CoupleResponse] = None
    members: List[CoupleMemberResponse] = []
    
class CoupleInviteResponse(BaseModel):
    invite_code: str
    expires_at: datetime

class JoinCoupleRequest(BaseModel):
    invite_code: str
