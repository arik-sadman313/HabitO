"""add_couple_shared_data_sync

Revision ID: e3f456789012
Revises: d2e345678901
Create Date: 2026-10-02 21:50:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e3f456789012'
down_revision: Union[str, Sequence[str], None] = 'd2e345678901'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'shared_goals',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('couple_id', sa.UUID(), sa.ForeignKey('couples.id', ondelete='CASCADE'), nullable=False),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('target', sa.Float(), nullable=False),
        sa.Column('current_progress', sa.Float(), nullable=False, server_default='0.0'),
        sa.Column('unit', sa.String(), nullable=True),
        sa.Column('deadline', sa.DateTime(), nullable=True),
        sa.Column('is_completed', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('is_deleted', sa.Boolean(), nullable=True, server_default='false'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_shared_goals_couple_id'), 'shared_goals', ['couple_id'], unique=False)

    op.create_table(
        'shared_habits',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('couple_id', sa.UUID(), sa.ForeignKey('couples.id', ondelete='CASCADE'), nullable=False),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('frequency', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('is_deleted', sa.Boolean(), nullable=True, server_default='false'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_shared_habits_couple_id'), 'shared_habits', ['couple_id'], unique=False)

    op.create_table(
        'shared_activities',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('couple_id', sa.UUID(), sa.ForeignKey('couples.id', ondelete='CASCADE'), nullable=False),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('start_time', sa.DateTime(), nullable=False),
        sa.Column('end_time', sa.DateTime(), nullable=True),
        sa.Column('is_completed', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('is_deleted', sa.Boolean(), nullable=True, server_default='false'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_shared_activities_couple_id'), 'shared_activities', ['couple_id'], unique=False)

    op.create_table(
        'memories',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('couple_id', sa.UUID(), sa.ForeignKey('couples.id', ondelete='CASCADE'), nullable=False),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('date', sa.DateTime(), nullable=False),
        sa.Column('media_url', sa.String(), nullable=True),
        sa.Column('tags', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('is_deleted', sa.Boolean(), nullable=True, server_default='false'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_memories_couple_id'), 'memories', ['couple_id'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_memories_couple_id'), table_name='memories')
    op.drop_table('memories')
    op.drop_index(op.f('ix_shared_activities_couple_id'), table_name='shared_activities')
    op.drop_table('shared_activities')
    op.drop_index(op.f('ix_shared_habits_couple_id'), table_name='shared_habits')
    op.drop_table('shared_habits')
    op.drop_index(op.f('ix_shared_goals_couple_id'), table_name='shared_goals')
    op.drop_table('shared_goals')
