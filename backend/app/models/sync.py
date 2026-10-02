import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, BigInteger, Boolean
from sqlalchemy.dialects.postgresql import UUID, JSONB

from app.models.base import Base

class SyncChange(Base):
    __tablename__ = "sync_changes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    entity_type = Column(String, nullable=False, index=True)
    entity_id = Column(String, nullable=False, index=True)
    scope_type = Column(String, nullable=False, index=True) # "user" or "couple"
    scope_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    operation = Column(String, nullable=False) # "upsert" or "delete"
    from sqlalchemy import Identity
    version = Column(BigInteger, Identity(), unique=True, index=True)
    changed_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    changed_by = Column(UUID(as_uuid=True), nullable=False)
    payload = Column(JSONB, nullable=True)
    is_deleted = Column(Boolean, default=False)
