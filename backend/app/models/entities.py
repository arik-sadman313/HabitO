import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Boolean, Float, Text, Integer, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.models.base import Base

class Tracker(Base):
    __tablename__ = "trackers"

    id = Column(UUID(as_uuid=True), primary_key=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=True) # None for generic shared, but mostly personal
    name = Column(String, nullable=False)
    icon = Column(String, nullable=False)
    color = Column(String, nullable=False)
    type = Column(String, nullable=False) # e.g., 'boolean', 'numeric', 'duration'
    unit = Column(String, nullable=True)
    is_shared = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False)

class TrackerLog(Base):
    __tablename__ = "tracker_logs"

    id = Column(UUID(as_uuid=True), primary_key=True)
    tracker_id = Column(UUID(as_uuid=True), ForeignKey('trackers.id', ondelete='CASCADE'), index=True, nullable=False)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    timestamp = Column(DateTime, nullable=False)
    value_num = Column(Float, nullable=True)
    value_text = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False)

class Habit(Base):
    __tablename__ = "habits"

    id = Column(UUID(as_uuid=True), primary_key=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    tracker_id = Column(UUID(as_uuid=True), ForeignKey('trackers.id', ondelete='CASCADE'), index=True, nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    frequency = Column(String, nullable=False) # Serialized HabitFrequency
    target_value = Column(Float, nullable=False)
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=True)
    is_shared = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False)

class HabitLog(Base):
    __tablename__ = "habit_logs"

    id = Column(UUID(as_uuid=True), primary_key=True)
    habit_id = Column(UUID(as_uuid=True), ForeignKey('habits.id', ondelete='CASCADE'), index=True, nullable=False)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    date = Column(DateTime, nullable=False)
    is_completed = Column(Boolean, default=False, nullable=False)
    progress_value = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False) # Using logical deletion just in case, though app might do hard delete

class Activity(Base):
    __tablename__ = "activities"

    id = Column(UUID(as_uuid=True), primary_key=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    title = Column(String, nullable=False)
    notes = Column(Text, nullable=True)
    scheduled_start = Column(DateTime, nullable=False)
    scheduled_end = Column(DateTime, nullable=True)
    is_completed = Column(Boolean, default=False, nullable=False)
    category = Column(String, nullable=True)
    is_shared = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False)

class StudySubject(Base):
    __tablename__ = "study_subjects"

    id = Column(UUID(as_uuid=True), primary_key=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    icon = Column(String, nullable=False)
    color = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False)

class StudySession(Base):
    __tablename__ = "study_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    subject_id = Column(UUID(as_uuid=True), ForeignKey('study_subjects.id', ondelete='CASCADE'), index=True, nullable=False)
    started_at = Column(DateTime, nullable=False)
    ended_at = Column(DateTime, nullable=True)
    duration = Column(Float, nullable=False, default=0.0)
    notes = Column(Text, nullable=True)
    session_type = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False)

class Meal(Base):
    __tablename__ = "meals"

    id = Column(UUID(as_uuid=True), primary_key=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    meal_type = Column(String, nullable=False)
    recorded_at = Column(DateTime, nullable=False)
    notes = Column(Text, nullable=True)
    photo_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False)

class MealItem(Base):
    __tablename__ = "meal_items"

    id = Column(UUID(as_uuid=True), primary_key=True)
    meal_id = Column(UUID(as_uuid=True), ForeignKey('meals.id', ondelete='CASCADE'), index=True, nullable=False)
    name = Column(String, nullable=False)
    quantity = Column(Float, nullable=False)
    unit = Column(String, nullable=False)
    calories = Column(Float, nullable=True)
    protein = Column(Float, nullable=True)
    carbs = Column(Float, nullable=True)
    fat = Column(Float, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False)

class SleepRecord(Base):
    __tablename__ = "sleep_records"

    id = Column(UUID(as_uuid=True), primary_key=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    sleep_start = Column(DateTime, nullable=False)
    wake_time = Column(DateTime, nullable=False)
    duration = Column(Float, nullable=False)
    quality = Column(Float, nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False)

class ExerciseSession(Base):
    __tablename__ = "exercise_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    exercise_type = Column(String, nullable=False)
    started_at = Column(DateTime, nullable=False)
    ended_at = Column(DateTime, nullable=False)
    duration = Column(Float, nullable=False)
    distance = Column(Float, nullable=True)
    calories = Column(Float, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False)

class MoodLog(Base):
    __tablename__ = "mood_logs"

    id = Column(UUID(as_uuid=True), primary_key=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    date = Column(DateTime, nullable=False)
    mood_rating = Column(Integer, nullable=False)
    energy_rating = Column(Integer, nullable=False)
    stress_rating = Column(Integer, nullable=False)
    note = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False)

class JournalEntry(Base):
    __tablename__ = "journal_entries"

    id = Column(UUID(as_uuid=True), primary_key=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    journal_type = Column(Integer, nullable=False)  # 0=personal, 1=shared (JournalType enum index)
    title = Column(String, nullable=True)
    body = Column(Text, nullable=False)
    mood_id = Column(UUID(as_uuid=True), ForeignKey('mood_logs.id', ondelete='SET NULL'), nullable=True)
    date = Column(DateTime, nullable=False)
    tags = Column(Text, nullable=True)
    photo_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False)

class PersonalGoal(Base):
    __tablename__ = "personal_goals"

    id = Column(UUID(as_uuid=True), primary_key=True)
    user_id = Column(UUID(as_uuid=True), index=True, nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    goal_type = Column(String, nullable=False)
    target_value = Column(Float, nullable=False)
    current_value = Column(Float, nullable=True)
    unit = Column(String, nullable=True)
    start_date = Column(DateTime, nullable=False)
    target_date = Column(DateTime, nullable=True)
    status = Column(Integer, nullable=False)  # 0=active, 1=completed, 2=archived (GoalStatus enum index)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    is_deleted = Column(Boolean, default=False)

