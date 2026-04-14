from __future__ import annotations

import json
from datetime import datetime

from sqlalchemy import (
    JSON,
    Boolean,
    DateTime,
    Float,
    ForeignKey,
    Index,
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


class PasswordResetToken(Base):
    """One-time token for /auth/forgot-password → /auth/reset-password flow."""

    __tablename__ = "password_reset_tokens"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    token: Mapped[str] = mapped_column(String(128), unique=True, index=True, nullable=False)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    used_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class MasterWine(Base):
    """
    LCBO master catalog row. Raw LCBO fields live in record_json; frequently
    queried columns are denormalized for indexes and simple SQL filters.
    """

    __tablename__ = "master_wines"
    __table_args__ = (
        Index("ix_master_wines_price_numeric", "price_numeric"),
        Index("ix_master_wines_systitle", "systitle"),
    )

    sku: Mapped[str] = mapped_column(String(120), primary_key=True)
    record_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    systitle: Mapped[str | None] = mapped_column(Text, nullable=True)
    ec_final_price: Mapped[str | None] = mapped_column(Text, nullable=True)
    ec_thumbnails: Mapped[str | None] = mapped_column(Text, nullable=True)
    lcbo_tastingnotes: Mapped[str | None] = mapped_column(Text, nullable=True)
    price_numeric: Mapped[float | None] = mapped_column(Float, nullable=True)

    name: Mapped[str | None] = mapped_column(Text, nullable=True)
    winery: Mapped[str | None] = mapped_column(Text, nullable=True)
    vintage: Mapped[str | None] = mapped_column(Text, nullable=True)
    country: Mapped[str | None] = mapped_column(Text, nullable=True)
    region: Mapped[str | None] = mapped_column(Text, nullable=True)
    subregion: Mapped[str | None] = mapped_column(Text, nullable=True)
    appellation: Mapped[str | None] = mapped_column(Text, nullable=True)
    varietals_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    style: Mapped[str | None] = mapped_column(Text, nullable=True)
    body: Mapped[str | None] = mapped_column(Text, nullable=True)
    acidity: Mapped[str | None] = mapped_column(Text, nullable=True)
    tannin: Mapped[str | None] = mapped_column(Text, nullable=True)
    sweetness: Mapped[str | None] = mapped_column(Text, nullable=True)
    oak: Mapped[str | None] = mapped_column(Text, nullable=True)
    alcohol_level: Mapped[str | None] = mapped_column(Text, nullable=True)
    fruit_tags_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    savory_tags_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    floral_tags_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    spice_tags_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    earth_tags_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    food_pairing_tags_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    currency: Mapped[str | None] = mapped_column(Text, nullable=True)
    image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    lcbo_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    inventory_status: Mapped[str | None] = mapped_column(Text, nullable=True)
    quality_confidence: Mapped[str | None] = mapped_column(Text, nullable=True)
    source_type: Mapped[str | None] = mapped_column(Text, nullable=True)
    source_updated_at: Mapped[str | None] = mapped_column(Text, nullable=True)

