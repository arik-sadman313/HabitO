from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from datetime import timedelta
from jose import jwt, JWTError

from app.core.database import get_db
from app.core.config import settings
from app.core.security import get_password_hash, verify_password, create_access_token, create_refresh_token
from app.models.user import User, RefreshToken
from app.schemas.auth import UserCreate, UserLogin, Token, UserResponse, TokenRefresh, PasswordChangeRequest
import secrets
from datetime import datetime, timedelta

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = db.query(User).filter(User.id == user_id, User.is_deleted == False).first()
    if user is None:
        raise credentials_exception
    return user

@router.post("/register", response_model=UserResponse)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == user_in.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    user = User(
        email=user_in.email,
        display_name=user_in.display_name,
        password_hash=get_password_hash(user_in.password)
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

@router.post("/login", response_model=Token)
def login(user_in: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == user_in.email, User.is_deleted == False).first()
    if not user or not verify_password(user_in.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    
    access_token = create_access_token(user.id)
    refresh_token_str = secrets.token_urlsafe(32)
    
    db_refresh = RefreshToken(
        user_id=user.id,
        token=refresh_token_str,
        expires_at=datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    )
    db.add(db_refresh)
    db.commit()

    return {
        "access_token": access_token,
        "refresh_token": refresh_token_str,
        "token_type": "bearer"
    }

@router.post("/refresh", response_model=Token)
def refresh(token_in: TokenRefresh, db: Session = Depends(get_db)):
    db_token = db.query(RefreshToken).filter(
        RefreshToken.token == token_in.refresh_token,
        RefreshToken.is_revoked == False,
        RefreshToken.expires_at > datetime.utcnow()
    ).first()
    
    if not db_token:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")
    
    user = db.query(User).filter(User.id == db_token.user_id, User.is_deleted == False).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
        
    db_token.is_revoked = True
    
    new_refresh = secrets.token_urlsafe(32)
    new_db_token = RefreshToken(
        user_id=user.id,
        token=new_refresh,
        expires_at=datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    )
    db.add(new_db_token)
    db.commit()
    
    return {
        "access_token": create_access_token(user.id),
        "refresh_token": new_refresh,
        "token_type": "bearer"
    }

@router.post("/logout")
def logout(token_in: TokenRefresh, db: Session = Depends(get_db)):
    db_token = db.query(RefreshToken).filter(RefreshToken.token == token_in.refresh_token).first()
    if db_token:
        db_token.is_revoked = True
        db.commit()
    return {"status": "success"}

@router.post("/password")
def change_password(pass_in: PasswordChangeRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not verify_password(pass_in.current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Incorrect current password")
    
    current_user.password_hash = get_password_hash(pass_in.new_password)
    
    db.query(RefreshToken).filter(RefreshToken.user_id == current_user.id).update({"is_revoked": True})
    
    db.commit()
    return {"status": "success"}

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user

@router.patch("/me", response_model=UserResponse)
def update_me(update_in: ProfileUpdateRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if update_in.display_name is not None:
        current_user.display_name = update_in.display_name
    if update_in.timezone is not None:
        current_user.timezone = update_in.timezone
    
    db.commit()
    db.refresh(current_user)
    return current_user

@router.delete("/me")
def delete_me(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    # Soft delete the user
    current_user.is_deleted = True
    
    # Revoke all refresh tokens
    db.query(RefreshToken).filter(RefreshToken.user_id == current_user.id).update({"is_revoked": True})
    
    from app.models.couple import Couple
    
    # Orphan active couples
    active_couple = db.query(Couple).filter(
        (Couple.user1_id == current_user.id) | (Couple.user2_id == current_user.id),
        Couple.status == 'active'
    ).first()
    
    if active_couple:
        active_couple.status = 'inactive'
    
    db.commit()
    return {"status": "success"}
