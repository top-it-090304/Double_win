"""order granted_at and user_entitlements for TASK-08

Revision ID: 20260401_0002
Revises: 20260401_0001
Create Date: 2026-04-01
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "20260401_0002"
down_revision: Union[str, Sequence[str], None] = "20260401_0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("orders", sa.Column("granted_at", sa.DateTime(timezone=True), nullable=True))

    op.create_table(
        "user_entitlements",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("user_id", sa.String(length=64), nullable=False),
        sa.Column("sku", sa.String(length=128), nullable=False),
        sa.Column("order_id", sa.Integer(), nullable=False),
        sa.Column("granted_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["order_id"], ["orders.id"], ondelete="RESTRICT"),
        sa.UniqueConstraint("order_id", name="uq_user_entitlements_order_id"),
    )
    op.create_index("ix_user_entitlements_user_id", "user_entitlements", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_user_entitlements_user_id", table_name="user_entitlements")
    op.drop_table("user_entitlements")
    op.drop_column("orders", "granted_at")
