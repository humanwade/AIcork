from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, EmailStr, Field


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(min_length=1)
    new_password: str = Field(min_length=8, max_length=128)


class DeleteAccountRequest(BaseModel):
    current_password: str = Field(min_length=1, description="Required to confirm account deletion")


class SignupRequest(BaseModel):
    first_name: str = Field(min_length=1, max_length=120)
    last_name: str = Field(min_length=1, max_length=120)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    phone_number: Optional[str] = Field(default=None, max_length=40)


class SendVerificationCodeRequest(BaseModel):
    """
    Payload for /auth/send-verification-code.

    Password is intentionally optional because email verification happens
    before the user enters their password in the signup flow.
    """

    first_name: str = Field(min_length=1, max_length=120)
    last_name: str = Field(min_length=1, max_length=120)
    email: EmailStr
    password: Optional[str] = None
    phone_number: Optional[str] = Field(default=None, max_length=40)


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserPublic(BaseModel):
    id: int
    email: EmailStr
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone_number: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    first_name: Optional[str] = Field(default=None, max_length=120)
    last_name: Optional[str] = Field(default=None, max_length=120)
    phone_number: Optional[str] = Field(default=None, max_length=40)


class WineEntryCreate(BaseModel):
    wine_name: str = Field(min_length=1, max_length=240)
    wine_type: str = Field(default="Other", max_length=40)
    rating: Optional[float] = Field(default=None, ge=0, le=5)
    tasting_notes: Optional[str] = None
    is_tried: bool = False
    image_path: Optional[str] = None
    image_url: Optional[str] = None
    sku: Optional[str] = None
    price: Optional[float] = None
    thumbnail_url: Optional[str] = None
    sommelier_note: Optional[str] = None
    inventory_url: Optional[str] = None
    tasted_at: Optional[datetime] = None
    flavors: Optional[List[str]] = None
    aromas: Optional[List[str]] = None
    body_style: Optional[List[str]] = None
    purchase_notes: Optional[str] = None


class WineEntryUpdate(BaseModel):
    wine_name: Optional[str] = Field(default=None, max_length=240)
    wine_type: Optional[str] = Field(default=None, max_length=40)
    rating: Optional[float] = Field(default=None, ge=0, le=5)
    tasting_notes: Optional[str] = None
    is_tried: Optional[bool] = None
    image_path: Optional[str] = None
    image_url: Optional[str] = None
    price: Optional[float] = None
    thumbnail_url: Optional[str] = None
    sommelier_note: Optional[str] = None
    inventory_url: Optional[str] = None
    tasted_at: Optional[datetime] = None
    flavors: Optional[List[str]] = None
    aromas: Optional[List[str]] = None
    body_style: Optional[List[str]] = None
    purchase_notes: Optional[str] = None


class CellarInsightsOut(BaseModel):
    """Taste profile summary for My Cellar insights card."""

    summary_text: Optional[str] = None
    preferred_wine_types: List[str] = []
    preferred_flavors: List[str] = []
    preferred_body_styles: List[str] = []
    average_preferred_price: Optional[float] = None
    enough_data: bool = False


class WineEntryOut(BaseModel):
    id: int
    user_id: int
    wine_name: str
    wine_type: str
    rating: Optional[float]
    tasting_notes: Optional[str]
    is_tried: bool
    image_path: Optional[str]
    image_url: Optional[str]
    sku: Optional[str]
    price: Optional[float]
    thumbnail_url: Optional[str]
    sommelier_note: Optional[str]
    inventory_url: Optional[str]
    tasted_at: Optional[datetime] = None
    flavors: Optional[List[str]] = None
    aromas: Optional[List[str]] = None
    body_style: Optional[List[str]] = None
    purchase_notes: Optional[str] = None
    added_at: datetime

    class Config:
        from_attributes = True


class CustomWineSaveRequest(BaseModel):
    """
    Payload for saving an unmatched scan result to the user's cellar without
    polluting the global master_wines catalog.
    """

    recognized_name: Optional[str] = Field(default=None, max_length=240)
    recognized_winery: Optional[str] = Field(default=None, max_length=240)
    recognized_vintage: Optional[str] = Field(default=None, max_length=40)

    edited_name: Optional[str] = Field(default=None, max_length=240)
    edited_winery: Optional[str] = Field(default=None, max_length=240)
    edited_vintage: Optional[str] = Field(default=None, max_length=40)

    image_url: Optional[str] = None
    is_tried: bool = False
    rating: Optional[float] = Field(default=None, ge=0, le=5)
    tasting_notes: Optional[str] = None


class ScanHistoryCreate(BaseModel):
    wine_name: str = Field(min_length=1, max_length=240)
    sku: Optional[str] = Field(default=None, max_length=80)
    image_url: Optional[str] = Field(default=None, max_length=500)


class ScanHistoryOut(BaseModel):
    id: int
    user_id: int
    wine_name: str
    sku: Optional[str]
    image_url: Optional[str]
    scanned_at: datetime

    class Config:
        from_attributes = True

