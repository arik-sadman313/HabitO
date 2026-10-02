"""add_screen_time_sync

Revision ID: d2e345678901
Revises: c1f234567890
Create Date: 2026-10-02 18:41:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd2e345678901'
down_revision: Union[str, Sequence[str], None] = 'c1f234567890'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'screen_time_daily_snapshots',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('date', sa.DateTime(), nullable=False),
        sa.Column('total_duration_seconds', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('app_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('is_deleted', sa.Boolean(), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_screen_time_daily_snapshots_user_id'), 'screen_time_daily_snapshots', ['user_id'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_screen_time_daily_snapshots_user_id'), table_name='screen_time_daily_snapshots')
    op.drop_table('screen_time_daily_snapshots')
