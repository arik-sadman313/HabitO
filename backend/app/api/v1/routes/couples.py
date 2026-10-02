import string
import random
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_

from app.core.database import get_db
from app.api.v1.routes.auth import get_current_user
from app.models.user import User
from app.models.couple import Couple, CoupleMember
from app.schemas.couple import CoupleResponse, CoupleInviteResponse, JoinCoupleRequest, CoupleMeResponse, CoupleMemberResponse

router = APIRouter()

def get_active_couple_member(db: Session, user_id):
    return db.query(CoupleMember).join(Couple).filter(
        CoupleMember.user_id == user_id,
        Couple.status == "active"
    ).first()

@router.post("/", response_model=CoupleResponse)
def create_couple(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Check if user is already in an active couple
    existing_member = get_active_couple_member(db, current_user.id)
    if existing_member:
        raise HTTPException(status_code=400, detail="User is already in an active couple")
    
    couple = Couple(status="active")
    db.add(couple)
    db.flush()
    
    member = CoupleMember(couple_id=couple.id, user_id=current_user.id, role="admin")
    db.add(member)
    db.commit()
    db.refresh(couple)
    return couple

@router.post("/invite", response_model=CoupleInviteResponse)
def generate_invite(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    member = get_active_couple_member(db, current_user.id)
    if not member:
        raise HTTPException(status_code=404, detail="Not in an active couple")
    
    couple = db.query(Couple).filter(Couple.id == member.couple_id).first()
    
    # Generate 6 char random code
    code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
    
    couple.invite_code = code
    couple.invite_expires_at = datetime.utcnow() + timedelta(days=1)
    db.commit()
    db.refresh(couple)
    
    return CoupleInviteResponse(invite_code=code, expires_at=couple.invite_expires_at)

@router.post("/join", response_model=CoupleResponse)
def join_couple(request: JoinCoupleRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    existing_member = get_active_couple_member(db, current_user.id)
    if existing_member:
        raise HTTPException(status_code=400, detail="User is already in an active couple")
    
    couple = db.query(Couple).filter(
        Couple.invite_code == request.invite_code,
        Couple.status == "active",
        Couple.invite_expires_at > datetime.utcnow()
    ).first()
    
    if not couple:
        raise HTTPException(status_code=404, detail="Invalid or expired invite code")
        
    # Check capacity (max 2)
    member_count = db.query(CoupleMember).filter(CoupleMember.couple_id == couple.id).count()
    if member_count >= 2:
        raise HTTPException(status_code=400, detail="Couple is full")
        
    new_member = CoupleMember(couple_id=couple.id, user_id=current_user.id, role="member")
    db.add(new_member)
    
    # Invalidate code
    couple.invite_code = None
    couple.invite_expires_at = None
    
    db.commit()
    db.refresh(couple)
    return couple

@router.delete("/leave")
def leave_couple(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    member = get_active_couple_member(db, current_user.id)
    if not member:
        raise HTTPException(status_code=404, detail="Not in an active couple")
        
    db.delete(member)
    db.commit()
    
    return {"detail": "Successfully left couple"}

@router.get("/me", response_model=CoupleMeResponse)
def get_my_couple(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    member = get_active_couple_member(db, current_user.id)
    if not member:
        return CoupleMeResponse(couple=None, members=[])
        
    couple = db.query(Couple).filter(Couple.id == member.couple_id).first()
    members = db.query(CoupleMember).filter(CoupleMember.couple_id == couple.id).all()
    
    return CoupleMeResponse(
        couple=CoupleResponse.model_validate(couple),
        members=[CoupleMemberResponse.model_validate(m) for m in members]
    )
