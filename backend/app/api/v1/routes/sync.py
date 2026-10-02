from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import asc
from datetime import datetime

from app.core.database import get_db
from app.api.v1.routes.auth import get_current_user
from app.models.user import User
from app.models.sync import SyncChange
from app.models.entities import Tracker, TrackerLog, Habit, HabitLog, Activity, StudySubject, StudySession, Meal, MealItem, SleepRecord, ExerciseSession, MoodLog, JournalEntry, PersonalGoal
from app.schemas.sync import SyncPushRequest, SyncPullResponse, SyncOperation
from app.schemas.entities import TrackerDto, TrackerLogDto, HabitDto, HabitLogDto, ActivityDto, StudySubjectDto, StudySessionDto, MealDto, MealItemDto, SleepRecordDto, ExerciseSessionDto, MoodLogDto, JournalEntryDto, PersonalGoalDto

router = APIRouter()

ENTITY_MODELS = {
    "tracker": (Tracker, TrackerDto),
    "tracker_log": (TrackerLog, TrackerLogDto),
    "habit": (Habit, HabitDto),
    "habit_log": (HabitLog, HabitLogDto),
    "activity": (Activity, ActivityDto),
    "study_subject": (StudySubject, StudySubjectDto),
    "study_session": (StudySession, StudySessionDto),
    "meal": (Meal, MealDto),
    "meal_item": (MealItem, MealItemDto),
    "sleep_record": (SleepRecord, SleepRecordDto),
    "exercise_session": (ExerciseSession, ExerciseSessionDto),
    "mood_log": (MoodLog, MoodLogDto),
    "journal_entry": (JournalEntry, JournalEntryDto),
    "personal_goal": (PersonalGoal, PersonalGoalDto),
}

@router.post("/push")
def push_changes(request: SyncPushRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    added_changes = 0
    for op in request.operations:
        # Validate ownership (Phase 14 focuses on Personal Data)
        if str(op.scope_id) != str(current_user.id):
            raise HTTPException(status_code=403, detail="Not authorized to modify this scope")
            
        if op.entity_type not in ENTITY_MODELS:
            # For now, skip unknown entities
            continue

        model_class, dto_class = ENTITY_MODELS[op.entity_type]
        
        try:
            if op.operation == "upsert" and op.payload:
                dto = dto_class(**op.payload)
                if op.entity_type == "meal_item":
                    meal = db.query(Meal).filter_by(id=dto.meal_id).first()
                    if not meal or str(meal.user_id) != str(current_user.id):
                        raise HTTPException(status_code=403, detail="Not authorized to modify this meal item")
                else:
                    if hasattr(dto, 'user_id') and str(dto.user_id) != str(current_user.id):
                        raise HTTPException(status_code=403, detail="Payload user_id mismatch")
                    
                existing = db.query(model_class).filter_by(id=dto.id).first()
                if existing:
                    for key, value in dto.model_dump().items():
                        setattr(existing, key, value)
                else:
                    new_entity = model_class(**dto.model_dump())
                    db.add(new_entity)
                db.flush()
            
            elif op.operation == "delete":
                existing = db.query(model_class).filter_by(id=op.entity_id).first()
                if existing:
                    existing.is_deleted = True
                    existing.updated_at = datetime.utcnow()
                db.flush()
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=422, detail=f"Malformed payload for {op.entity_type}: {str(e)}")

        # Log the change
        change = SyncChange(
            entity_type=op.entity_type,
            entity_id=op.entity_id,
            scope_type=op.scope_type,
            scope_id=op.scope_id,
            operation=op.operation,
            changed_at=op.changed_at,
            changed_by=current_user.id,
            payload=op.payload,
            is_deleted=op.is_deleted,
        )
        db.add(change)
        added_changes += 1
        
    db.commit()
    return {"status": "ok", "changes_processed": added_changes}

@router.get("/pull", response_model=SyncPullResponse)
def pull_changes(cursor: int = 0, limit: int = 100, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Personal data only for Phase 14
    changes = db.query(SyncChange).filter(
        SyncChange.version > cursor,
        SyncChange.scope_id == current_user.id
    ).order_by(asc(SyncChange.version)).limit(limit).all()
    
    last_cursor = cursor
    if changes:
        last_cursor = changes[-1].version
        
    result_changes = []
    for c in changes:
        result_changes.append({
            "entity_type": c.entity_type,
            "entity_id": c.entity_id,
            "scope_type": c.scope_type,
            "scope_id": str(c.scope_id),
            "operation": c.operation,
            "changed_at": c.changed_at.isoformat(),
            "payload": c.payload,
            "is_deleted": c.is_deleted,
            "version": c.version
        })
        
    return {
        "cursor": last_cursor,
        "changes": result_changes,
        "has_more": len(changes) == limit
    }
