from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime
from uuid import UUID

class TrackerDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: Optional[UUID] = None
    name: str
    icon: str
    color: str
    type: str
    unit: Optional[str] = None
    is_shared: bool = True
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

class TrackerLogDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    tracker_id: UUID
    user_id: UUID
    timestamp: datetime
    value_num: Optional[float] = None
    value_text: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

class HabitDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    tracker_id: UUID
    title: str
    description: Optional[str] = None
    frequency: str
    target_value: float
    start_date: datetime
    end_date: Optional[datetime] = None
    is_shared: bool = True
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

class HabitLogDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    habit_id: UUID
    user_id: UUID
    date: datetime
    is_completed: bool
    progress_value: float
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

class ActivityDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    title: str
    notes: Optional[str] = None
    scheduled_start: datetime
    scheduled_end: Optional[datetime] = None
    is_completed: bool = False
    category: Optional[str] = None
    is_shared: bool = True
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

class StudySubjectDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    user_id: UUID
    name: str
    description: Optional[str] = None
    icon: str
    color: str
    is_active: bool = True
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

class StudySessionDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    user_id: UUID
    subject_id: UUID
    started_at: datetime
    ended_at: Optional[datetime] = None
    duration: float = 0.0
    notes: Optional[str] = None
    session_type: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

class MealDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    user_id: UUID
    meal_type: str
    recorded_at: datetime
    notes: Optional[str] = None
    photo_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

class MealItemDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    meal_id: UUID
    name: str
    quantity: float
    unit: str
    calories: Optional[float] = None
    protein: Optional[float] = None
    carbs: Optional[float] = None
    fat: Optional[float] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

class SleepRecordDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    user_id: UUID
    sleep_start: datetime
    wake_time: datetime
    duration: float
    quality: float
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

class ExerciseSessionDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    user_id: UUID
    exercise_type: str
    started_at: datetime
    ended_at: datetime
    duration: float
    distance: Optional[float] = None
    calories: Optional[float] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

class MoodLogDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    user_id: UUID
    date: datetime
    mood_rating: int
    energy_rating: int
    stress_rating: int
    note: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

class JournalEntryDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    user_id: UUID
    journal_type: int  # 0=personal, 1=shared (JournalType enum index)
    title: Optional[str] = None
    body: str
    mood_id: Optional[UUID] = None
    date: datetime
    tags: Optional[str] = None
    photo_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

class PersonalGoalDto(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    user_id: UUID
    title: str
    description: Optional[str] = None
    goal_type: str
    target_value: float
    current_value: Optional[float] = None
    unit: Optional[str] = None
    start_date: datetime
    target_date: Optional[datetime] = None
    status: int  # GoalStatus enum index
    created_at: datetime
    updated_at: datetime
    is_deleted: bool = False

