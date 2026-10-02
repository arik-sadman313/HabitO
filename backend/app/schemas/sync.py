from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional, List, Any, Dict

class SyncOperation(BaseModel):
    entity_type: str
    entity_id: str
    scope_type: str
    scope_id: UUID
    operation: str
    changed_at: datetime
    payload: Optional[Dict[str, Any]] = None
    is_deleted: bool = False

class SyncPushRequest(BaseModel):
    device_id: str
    operations: List[SyncOperation]

class SyncPullResponse(BaseModel):
    cursor: int
    changes: List[dict]
    has_more: bool
