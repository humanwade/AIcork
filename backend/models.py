from __future__ import annotations

import json
from datetime import datetime

from sqlalchemy import (
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    first_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    last_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    phone_number: Mapped[str | None] = mapped_column(String(40), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    cellar_entries: Mapped[list["WineEntry"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
        lazy="selectin",
    )


class WineEntry(Base):
    __tablename__ = "wine_entries"
    __table_args__ = (
        UniqueConstraint("user_id", "sku", name="uq_user_sku"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)

    wine_name: Mapped[str] = mapped_column(String(240), nullable=False)
    wine_type: Mapped[str] = mapped_column(String(40), nullable=False, default="Other")

    rating: Mapped[float | None] = mapped_column(Float, nullable=True)
    tasting_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_tried: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    image_path: Mapped[str | None] = mapped_column(String(500), nullable=True)
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    sku: Mapped[str | None] = mapped_column(String(80), nullable=True)
    price: Mapped[float | None] = mapped_column(Float, nullable=True)
    thumbnail_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    sommelier_note: Mapped[str | None] = mapped_column(Text, nullable=True)
    inventory_url: Mapped[str | None] = mapped_column(String(700), nullable=True)

    # Tasting-specific fields (for is_tried entries)
    tasted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    flavors_json: Mapped[str | None] = mapped_column(Text, nullable=True)  # JSON array of strings
    aromas_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    body_style_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    purchase_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    added_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    user: Mapped["User"] = relationship(back_populates="cellar_entries")

    @property
    def flavors(self) -> list[str] | None:
        if not self.flavors_json:
            return None
        try:
            return json.loads(self.flavors_json)
        except (json.JSONDecodeError, TypeError):
            return None

    @property
    def aromas(self) -> list[str] | None:
        if not self.aromas_json:
            return None
        try:
            return json.loads(self.aromas_json)
        except (json.JSONDecodeError, TypeError):
            return None

    @property
    def body_style(self) -> list[str] | None:
        if not self.body_style_json:
            return None
        try:
            return json.loads(self.body_style_json)
        except (json.JSONDecodeError, TypeError):
            return None


class UserContributedWine(Base):
    """
    User-submitted scan confirmations/edits. This table is intentionally separate
    from the global master_wines catalog.
    """

    __tablename__ = "user_contributed_wines"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)

    recognized_name: Mapped[str | None] = mapped_column(String(240), nullable=True)
    recognized_winery: Mapped[str | None] = mapped_column(String(240), nullable=True)
    recognized_vintage: Mapped[str | None] = mapped_column(String(40), nullable=True)

    edited_name: Mapped[str | None] = mapped_column(String(240), nullable=True)
    edited_winery: Mapped[str | None] = mapped_column(String(240), nullable=True)
    edited_vintage: Mapped[str | None] = mapped_column(String(40), nullable=True)

    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    user: Mapped["User"] = relationship(lazy="selectin")


class ScanHistory(Base):
    __tablename__ = "scan_history"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    wine_name: Mapped[str] = mapped_column(String(240), nullable=False)
    sku: Mapped[str | None] = mapped_column(String(80), nullable=True)
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    scanned_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

