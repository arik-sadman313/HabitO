import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.models.base import Base

class Couple(Base):
    __tablename__ = "couples"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    status = Column(String, default="active", nullable=False)
    invite_code = Column(String, unique=True, index=True, nullable=True)
    invite_expires_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class CoupleMember(Base):
    __tablename__ = "couple_members"

    couple_id = Column(UUID(as_uuid=True), ForeignKey("couples.id"), primary_key=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), primary_key=True)
    role = Column(String, nullable=False, default="member")
    created_at = Column(DateTime, default=datetime.utcnow)
