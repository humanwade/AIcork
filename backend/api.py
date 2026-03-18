import base64
import difflib
import json
import random
import re
import string
import os
import sqlite3
import sys
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from dotenv import load_dotenv
from pathlib import Path
from pydantic import EmailStr

from fastapi import FastAPI, Depends, File, HTTPException, UploadFile, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_core.messages import HumanMessage
from langchain_google_genai import ChatGoogleGenerativeAI

from recommendation.pipeline import recommend_wines
from recommendation.wine_preferences import WinePreferences
from wine_type import normalize_wine_type
from discover import (
    discover_daily,
    discover_collections,
    discover_collection,
    discover_budget,
    discover_for_you,
    discover_recommended,
)

from database import init_db, get_db
from models import User, WineEntry, ScanHistory
from recommendation.user_profile import build_user_taste_profile
from schemas import (
    CellarInsightsOut,
    ChangePasswordRequest,
    CustomWineSaveRequest,
    DeleteAccountRequest,
    SendVerificationCodeRequest,
    SignupRequest,
    LoginResponse,
    UserPublic,
    UserUpdate,
    WineEntryCreate,
    WineEntryUpdate,
    WineEntryOut,
    ScanHistoryCreate,
    ScanHistoryOut,
)
from auth import (
    create_access_token,
    get_current_user,
    get_optional_current_user,
    hash_password,
    verify_password,
)
from email_utils import send_verification_email
from models import UserContributedWine

load_dotenv()

# ---------------------------------------------------------------------------
# Sections: (1) Imports (2) Env/Config (3) App + Middleware (4) Shared
#           (5) Auth (6) Profile (7) Cellar (8) Recommend (9) Scan (10) Health
# ---------------------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = BASE_DIR.parent
INDEX_DIR = PROJECT_ROOT / "data" / "wine_faiss_index"
PAIRINGS_DB_PATH = os.getenv("PAIRINGS_DB_PATH", str(PROJECT_ROOT / "data" / "pairings.db"))


class WinePreferencesIn(BaseModel):
    """Optional wine preferences from UI. Used for soft ranking only, never filtering."""

    preferred_styles: Optional[List[str]] = Field(
        default=None,
        description="Preferred wine styles: Red, White, Rosé, Sparkling",
    )
    preferred_body: Optional[str] = Field(
        default=None,
        description="Preferred body: Light, Medium, Full",
    )
    preferred_flavors: Optional[List[str]] = Field(
        default=None,
        description="Preferred flavor profile: Fruity, Crisp, Bold, Dry, Earthy, Smooth",
    )
    default_budget: Optional[float] = Field(
        default=None,
        ge=0,
        description="User default budget (for ranking bonus, not filtering)",
    )


class RecommendRequest(BaseModel):
    """
    Request model for /recommend.

    NOTE: The UI supplies budget via a dedicated slider; we treat max_budget as that
    value and NEVER attempt to parse price from the natural language query.
    """

    query: str = Field(..., description="User's natural language description of occasion or preference")
    max_budget: float = Field(50.0, description="Maximum price in CAD (from UI slider, not parsed)")
    top_k: int = Field(3, ge=1, le=10, description="Number of recommendations to return")
    wine_preferences: Optional[WinePreferencesIn] = Field(
        default=None,
        description="Optional wine preferences for soft ranking bonus (never filters results)",
    )


class WineResult(BaseModel):
    systitle: str
    ec_final_price: Optional[float]
    lcbo_tastingnotes: str
    ec_thumbnails: Optional[str]
    sku: Optional[str]
    inventory_url: Optional[str]
    sommelier_note: str
    similarity_reason: Optional[str] = None
    wine_type: Optional[str] = None


app = FastAPI(title="LCBO Wine Recommendation API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten later when frontend domain is fixed
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


vectorstore = None
llm = None


def _load_resources():
    """Lazy-load vectorstore and LLM once for the process. Uses GOOGLE_API_KEY from env."""
    global vectorstore, llm
    if vectorstore is not None and llm is not None:
        return

    print("[recommend] Loading FAISS index and Gemini LLM...")
    embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
    if not INDEX_DIR.exists():
        raise RuntimeError(f"FAISS index not found at {INDEX_DIR}. Build it with wine_index_builder.py first.")
    vs = FAISS.load_local(str(INDEX_DIR), embeddings, allow_dangerous_deserialization=True)
    print(f"[recommend] FAISS index loaded from {INDEX_DIR}")

    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        print("[recommend] GOOGLE_API_KEY not set; Gemini features will fail.")
    else:
        print(f"[recommend] GOOGLE_API_KEY configured (prefix: {api_key[:5]}...)")

    model = ChatGoogleGenerativeAI(
        model="gemini-2.5-flash-lite",
        google_api_key=api_key,
    )
    vectorstore = vs
    llm = model
    print("[recommend] Resource loading complete.")


def _get_master_wine_by_sku(sku: str) -> Optional[dict]:
    """Lookup master wine details by SKU from pairings.db master_wines."""
    if not sku:
        return None
    try:
        con = sqlite3.connect(PAIRINGS_DB_PATH)
        con.row_factory = sqlite3.Row
        cur = con.cursor()
        cur.execute("SELECT * FROM master_wines WHERE sku = ? LIMIT 1", (str(sku),))
        row = cur.fetchone()
        return dict(row) if row else None
    except Exception as e:
        print(f"[scan] master_wines lookup failed: {e}")
        return None
    finally:
        try:
            con.close()
        except Exception:
            pass


@app.on_event("startup")
async def startup_event():
    init_db()
    _load_resources()


# -----------------------------
# Auth
# -----------------------------

# In-memory email verification store for development.
# Maps email -> (code, expires_at, verified_flag)
_email_verification_store: Dict[str, Tuple[str, datetime, bool]] = {}


def _generate_verification_code() -> str:
    return "".join(random.choices(string.digits, k=6))


@app.post("/auth/send-verification-code")
async def send_verification_code(payload: SendVerificationCodeRequest, db: Session = Depends(get_db)):
    """
    Generate a 6-digit verification code for the given email.
    Sends the code via SMTP (see backend/email_utils.py).
    The code is also printed to backend logs for debugging.
    """
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    code = _generate_verification_code()
    expires_at = datetime.utcnow() + timedelta(minutes=5)
    _email_verification_store[payload.email] = (code, expires_at, False)
    print(f"[auth] Verification code for {payload.email}: {code} (expires at {expires_at.isoformat()}Z)")
    try:
        # Send synchronously so failures surface immediately to the client and logs.
        send_verification_email(payload.email, code)
        print(f"[auth] Verification email sent to {payload.email}")
    except Exception as e:
        print(f"[auth] Failed to send verification email to {payload.email}: {e}")
        raise HTTPException(status_code=500, detail="Failed to send verification email")
    return {"ok": True}


@app.post("/auth/verify-email-code")
async def verify_email_code(email: EmailStr, code: str):
    record = _email_verification_store.get(email)
    if not record:
        raise HTTPException(status_code=400, detail="No verification code found for this email")
    stored_code, expires_at, _ = record
    if datetime.utcnow() > expires_at:
        raise HTTPException(status_code=400, detail="Verification code has expired")
    if code != stored_code:
        raise HTTPException(status_code=400, detail="Invalid verification code")
    _email_verification_store[email] = (stored_code, expires_at, True)
    print(f"[auth] Email verified: {email}")
    return {"ok": True}


@app.post("/auth/signup", response_model=UserPublic)
async def signup(payload: SignupRequest, db: Session = Depends(get_db)):
    record = _email_verification_store.get(payload.email)
    if not record or not record[2]:
        raise HTTPException(status_code=400, detail="Email has not been verified")
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    user = User(
        email=payload.email,
        hashed_password=hash_password(payload.password),
        first_name=payload.first_name,
        last_name=payload.last_name,
        phone_number=payload.phone_number,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@app.post("/auth/login", response_model=LoginResponse)
async def login(
    form: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
):
    # OAuth2PasswordRequestForm uses "username" field; we treat it as email.
    user = db.query(User).filter(User.email == form.username).first()
    if not user or not verify_password(form.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    token = create_access_token(subject=user.email)
    print(f"[auth] Login success for {user.email}")
    return LoginResponse(access_token=token)


# -----------------------------
# Profile / account (protected)
# -----------------------------

@app.get("/auth/me", response_model=UserPublic)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@app.patch("/auth/me", response_model=UserPublic)
async def update_me(
    payload: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    data = payload.model_dump(exclude_unset=True)
    for key, value in data.items():
        setattr(current_user, key, value)
    db.commit()
    db.refresh(current_user)
    print(f"[auth] Profile updated for {current_user.email}")
    return current_user


@app.post("/auth/change-password")
async def change_password(
    payload: ChangePasswordRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Verify current password and set new password. No password in logs."""
    if not verify_password(payload.current_password, current_user.hashed_password):
        print(f"[auth] Change password failed for user_id={current_user.id}: current password incorrect")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect.",
        )
    current_user.hashed_password = hash_password(payload.new_password)
    db.commit()
    print(f"[auth] Password updated for user_id={current_user.id} ({current_user.email})")
    return {"message": "Password updated successfully."}


@app.delete("/auth/me")
async def delete_account(
    payload: DeleteAccountRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Delete the authenticated user only after verifying current password."""
    print(f"[auth] Delete account requested for user_id={current_user.id} ({current_user.email})")
    if not payload.current_password or not payload.current_password.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is required to delete your account.",
        )
    if not verify_password(payload.current_password, current_user.hashed_password):
        print(f"[auth] Delete account password verification failed for user_id={current_user.id}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Current password is incorrect.",
        )
    print(f"[auth] Delete account password verification succeeded for user_id={current_user.id}")
    db.delete(current_user)
    db.commit()
    print(f"[auth] Account deletion completed for user_id={current_user.id}")
    return {"message": "Your account has been deleted."}


# -----------------------------
# Cellar CRUD (protected)
# -----------------------------

@app.post("/cellar", response_model=WineEntryOut)
async def add_cellar_entry(
    payload: WineEntryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Server assigns owner from JWT; never trust client-supplied user_id.
    # If sku exists, prevent duplicates per user (UniqueConstraint also enforces).
    if payload.sku:
        existing = (
            db.query(WineEntry)
            .filter(WineEntry.user_id == current_user.id, WineEntry.sku == payload.sku)
            .first()
        )
        if existing:
            return existing

    entry = WineEntry(
        user_id=current_user.id,
        wine_name=payload.wine_name,
        wine_type=payload.wine_type or "Other",
        rating=payload.rating,
        tasting_notes=payload.tasting_notes,
        is_tried=payload.is_tried,
        image_path=payload.image_path,
        image_url=payload.image_url,
        sku=payload.sku,
        price=payload.price,
        thumbnail_url=payload.thumbnail_url,
        sommelier_note=payload.sommelier_note,
        inventory_url=payload.inventory_url,
        tasted_at=payload.tasted_at,
        flavors_json=json.dumps(payload.flavors) if payload.flavors else None,
        aromas_json=json.dumps(payload.aromas) if payload.aromas else None,
        body_style_json=json.dumps(payload.body_style) if payload.body_style else None,
        purchase_notes=payload.purchase_notes,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    print(f"[cellar] Creating cellar entry for user_id={current_user.id} ({current_user.email})")
    return entry


@app.post("/cellar/custom", response_model=WineEntryOut)
async def add_custom_cellar_entry(
    payload: CustomWineSaveRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Save a user-confirmed scan result to the user's cellar when no master DB match exists.
    This will:
    - insert a row into user_contributed_wines (separate from master_wines)
    - create a WineEntry owned by the current user (sku remains null)
    """
    edited_name = (payload.edited_name or "").strip() or None
    edited_winery = (payload.edited_winery or "").strip() or None
    edited_vintage = (payload.edited_vintage or "").strip() or None

    recognized_name = (payload.recognized_name or "").strip() or None
    recognized_winery = (payload.recognized_winery or "").strip() or None
    recognized_vintage = (payload.recognized_vintage or "").strip() or None

    final_name = edited_name or recognized_name
    final_winery = edited_winery or recognized_winery
    final_vintage = edited_vintage or recognized_vintage

    if not final_name and not final_winery:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Wine name or winery is required.",
        )

    title_parts = [p for p in [final_winery, final_name, final_vintage] if p]
    wine_title = " ".join(title_parts).strip()

    contrib = UserContributedWine(
        user_id=current_user.id,
        recognized_name=recognized_name,
        recognized_winery=recognized_winery,
        recognized_vintage=recognized_vintage,
        edited_name=edited_name,
        edited_winery=edited_winery,
        edited_vintage=edited_vintage,
        image_url=payload.image_url,
    )
    db.add(contrib)
    db.flush()

    entry = WineEntry(
        user_id=current_user.id,
        wine_name=wine_title,
        wine_type="Other",
        rating=payload.rating,
        tasting_notes=payload.tasting_notes,
        is_tried=payload.is_tried,
        image_url=payload.image_url,
        sku=None,
        price=None,
        thumbnail_url=payload.image_url,
        sommelier_note=None,
        inventory_url=None,
        tasted_at=datetime.utcnow() if payload.is_tried else None,
    )

    db.add(entry)
    db.commit()
    db.refresh(entry)

    print(f"[scan] user-contributed wine saved for user_id={current_user.id} entry_id={entry.id}")
    return entry


@app.get("/cellar", response_model=List[WineEntryOut])
async def list_cellar_entries(
    is_tried: Optional[bool] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Only return entries belonging to the authenticated user.
    q = db.query(WineEntry).filter(WineEntry.user_id == current_user.id)
    if is_tried is not None:
        q = q.filter(WineEntry.is_tried == is_tried)
    rows = q.order_by(WineEntry.added_at.desc()).all()
    print(f"[cellar] Fetching cellar for user_id={current_user.id} ({current_user.email}): {len(rows)} entries")
    return rows


@app.get("/cellar/insights", response_model=CellarInsightsOut)
async def get_cellar_insights(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Return taste profile summary for the current user's My Cellar insights card."""
    profile = build_user_taste_profile(db, current_user.id)
    if profile is None:
        return CellarInsightsOut(enough_data=False)
    return CellarInsightsOut(
        summary_text=profile.summary_text,
        preferred_wine_types=profile.preferred_wine_types,
        preferred_flavors=profile.preferred_flavors,
        preferred_body_styles=profile.preferred_body_styles,
        average_preferred_price=profile.average_preferred_price,
        enough_data=True,
    )


@app.patch("/cellar/{entry_id}", response_model=WineEntryOut)
@app.put("/cellar/{entry_id}", response_model=WineEntryOut)
async def update_cellar_entry(
    entry_id: int,
    payload: WineEntryUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Owner check: fetch by id first, then verify ownership.
    entry = db.query(WineEntry).filter(WineEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Wine entry not found")
    if entry.user_id != current_user.id:
        print(f"[cellar] Forbidden update attempt by user_id={current_user.id} on entry user_id={entry.user_id}")
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to modify this entry")

    data = payload.model_dump(exclude_unset=True)
    if "flavors" in data:
        entry.flavors_json = json.dumps(data["flavors"]) if data["flavors"] else None
        del data["flavors"]
    if "aromas" in data:
        entry.aromas_json = json.dumps(data["aromas"]) if data["aromas"] else None
        del data["aromas"]
    if "body_style" in data:
        entry.body_style_json = json.dumps(data["body_style"]) if data["body_style"] else None
        del data["body_style"]
    # If an entry is being reverted back to a "Want" (is_tried -> False),
    # clear all user-specific tasting fields and, when possible, restore
    # the base product metadata from master_wines so the Wants view shows
    # a normal saved wine (not a partial Tried record).
    if "is_tried" in data and data["is_tried"] is False:
        entry.rating = None
        entry.tasted_at = None
        entry.flavors_json = None
        entry.aromas_json = None
        entry.body_style_json = None
        entry.purchase_notes = None

        # If we have a SKU, try to restore base fields from master_wines.
        sku = entry.sku
        if sku:
            base = _get_master_wine_by_sku(sku)
            if base:
                title = str(base.get("systitle") or "").strip()
                notes = str(base.get("lcbo_tastingnotes") or "").strip()
                thumb = base.get("ec_thumbnails")
                raw_price = base.get("ec_final_price")
                try:
                    price_val = float(raw_price) if raw_price is not None else None
                except (TypeError, ValueError):
                    price_val = None

                entry.wine_name = title or entry.wine_name
                entry.tasting_notes = notes or entry.tasting_notes
                entry.price = price_val if price_val is not None else entry.price
                if thumb:
                    entry.thumbnail_url = thumb
                    # Prefer thumbnail as image if image_url is missing.
                    if not entry.image_url:
                        entry.image_url = thumb

                # Normalize wine type from base data so Wants cards show
                # the correct category.
                normalized_type = normalize_wine_type(
                    raw_style=base.get("style"),
                    title=title,
                    notes=notes,
                )
                if normalized_type:
                    entry.wine_type = normalized_type
    for k, v in data.items():
        if hasattr(entry, k):
            setattr(entry, k, v)
    print(f"[cellar] Tasting update for entry_id={entry_id} user_id={current_user.id}: fields saved")
    db.commit()
    db.refresh(entry)
    return entry


@app.delete("/cellar/{entry_id}")
async def delete_cellar_entry(
    entry_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Owner check: fetch by id first, then verify ownership.
    entry = db.query(WineEntry).filter(WineEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Wine entry not found")
    if entry.user_id != current_user.id:
        print(f"[cellar] Forbidden delete attempt by user_id={current_user.id} on entry user_id={entry.user_id}")
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to delete this entry")
    db.delete(entry)
    db.commit()
    return {"deleted": True, "id": entry_id}


# -----------------------------
# Recommendation
# -----------------------------

@app.post("/recommend", response_model=List[WineResult])
async def recommend(
    req: RecommendRequest,
    current_user: Optional[User] = Depends(get_optional_current_user),
    db: Session = Depends(get_db),
):
    """Return a list of recommended wines for the given query and budget.
    Authenticated users with Tried history receive subtle personalization.
    Wine preferences (if provided) add a soft ranking bonus; they never filter results."""
    _load_resources()

    wine_prefs: Optional[WinePreferences] = None
    if req.wine_preferences:
        wp = req.wine_preferences
        wine_prefs = WinePreferences(
            preferred_styles=wp.preferred_styles or [],
            preferred_body=wp.preferred_body or "",
            preferred_flavors=wp.preferred_flavors or [],
            default_budget=wp.default_budget or 0.0,
        )

    wine_payloads, score_debug = recommend_wines(
        query=req.query,
        max_budget=req.max_budget,
        top_k=req.top_k,
        vectorstore=vectorstore,
        llm=llm,
        db=db if current_user else None,
        user_id=current_user.id if current_user else None,
        wine_preferences=wine_prefs,
    )

    # Structured logging for debugging / ranking inspection.
    print(f"[recommend] parsed_query + ranking_debug_count={len(score_debug)}")

    return [
        WineResult(
            systitle=w["systitle"],
            ec_final_price=w["ec_final_price"],
            lcbo_tastingnotes=w["lcbo_tastingnotes"],
            ec_thumbnails=w["ec_thumbnails"],
            sku=w["sku"],
            inventory_url=w["inventory_url"],
            sommelier_note=w["sommelier_note"],
            wine_type=w.get("wine_type"),
        )
        for w in wine_payloads
    ]


@app.get("/wine/{sku}/similar", response_model=List[WineResult])
async def similar_wines(sku: str):
    """
    Return 3–5 wines similar to the given SKU, using FAISS semantic search.

    - Uses the master_wines row for the SKU as the query seed.
    - Excludes the original wine from the results.
    - Reuses existing metadata fields so the Flutter client can parse them
      with the same model it uses for recommendations.
    """
    _load_resources()

    base_row = _get_master_wine_by_sku(sku)
    if not base_row:
        return []

    base_title = str(base_row.get("systitle") or "").strip()
    base_notes = str(base_row.get("lcbo_tastingnotes") or "").strip()
    base_price_raw = base_row.get("ec_final_price")
    try:
        base_price = float(base_price_raw) if base_price_raw is not None else None
    except (TypeError, ValueError):
        base_price = None

    query = f"{base_title}. {base_notes}".strip() or base_title or base_notes
    if not query:
        return []

    # Use FAISS to fetch semantic neighbours.
    docs = vectorstore.similarity_search(query, k=16)

    results: List[WineResult] = []
    seen_skus = {str(sku)}
    seen_titles = {base_title.lower()}
    producer_counts: Dict[str, int] = {}

    def _normalize_title(t: str) -> str:
        return (t or "").strip().lower()

    def _producer_key(t: str) -> str:
        # Very lightweight producer heuristic: first 1–2 words of title.
        parts = _normalize_title(t).split()
        if not parts:
            return ""
        return " ".join(parts[:2])

    def _build_similarity_reason(
        base_title: str,
        base_notes: str,
        base_price: Optional[float],
        cand_title: str,
        cand_notes: str,
        cand_price: Optional[float],
    ) -> str:
        bt = base_title.lower()
        bn = base_notes.lower()
        ct = cand_title.lower()
        cn = cand_notes.lower()

        def has_any(text: str, keys: List[str]) -> bool:
            return any(k in text for k in keys)

        # Style-based cues
        if has_any(bt + bn, ["rosé", "rose"]) and has_any(ct + cn, ["rosé", "rose"]):
            return "Similar crisp rosé style"
        if has_any(bt + bn, ["sparkling", "prosecco", "cava"]) and has_any(
            ct + cn, ["sparkling", "prosecco", "cava"]
        ):
            return "Similar sparkling wine style"

        # Fruit / profile cues
        if has_any(bn, ["berry", "cherry", "raspberry"]) and has_any(
            cn, ["berry", "cherry", "raspberry"]
        ):
            return "Berry-forward and food-friendly"
        if has_any(bn, ["citrus", "lemon", "lime", "grapefruit"]) and has_any(
            cn, ["citrus", "lemon", "lime", "grapefruit"]
        ):
            return "Similar citrusy freshness"
        if has_any(bn, ["oak", "vanilla", "toast"]) and has_any(
            cn, ["oak", "vanilla", "toast"]
        ):
            return "Similar oak-driven profile"

        # Acidity / freshness
        if has_any(bn, ["crisp", "zesty", "fresh"]) and has_any(
            cn, ["crisp", "zesty", "fresh"]
        ):
            return "Similar acidity and freshness"

        # Price-based reason
        if base_price is not None and cand_price is not None:
            if base_price <= 20 and cand_price <= 20:
                return "Good alternative under $20"
            if abs(base_price - cand_price) <= 3:
                return "Similar style around the same price"

        # Fallback
        return "Similar flavour profile"

    for doc in docs:
        m = doc.metadata or {}
        ec_skus = m.get("ec_skus")
        cand_sku = m.get("permanentid") or (
            ec_skus[0] if isinstance(ec_skus, (list, tuple)) and ec_skus else None
        )
        if not cand_sku:
            continue
        cand_sku = str(cand_sku)
        if cand_sku in seen_skus:
            continue

        title_cand = m.get("systitle", "Unknown Wine")
        norm_title = _normalize_title(title_cand)
        if norm_title in seen_titles:
            continue

        raw_price = m.get("ec_final_price")
        try:
            price_val: Optional[float] = float(raw_price)
        except (TypeError, ValueError):
            price_val = None

        thumb = m.get("ec_thumbnails")
        notes_cand = m.get("lcbo_tastingnotes", "No tasting notes available.")
        normalized_type = normalize_wine_type(
            raw_style=m.get("style") or m.get("wine_style"),
            title=title_cand,
            notes=notes_cand,
        )

        # Diversity: avoid too many from the same rough producer.
        producer = _producer_key(title_cand)
        count = producer_counts.get(producer, 0)
        if producer and count >= 2:
            continue

        inventory_url = f"https://www.lcbo.com/en/storeinventory?sku={cand_sku}" if cand_sku else None

        reason = _build_similarity_reason(
            base_title,
            base_notes,
            base_price,
            title_cand,
            notes_cand,
            price_val,
        )

        results.append(
            WineResult(
                systitle=title_cand,
                ec_final_price=price_val,
                lcbo_tastingnotes=notes_cand,
                ec_thumbnails=thumb,
                sku=cand_sku,
                inventory_url=inventory_url,
                sommelier_note="",
                similarity_reason=reason,
                wine_type=normalized_type,
            )
        )
        seen_skus.add(cand_sku)
        seen_titles.add(norm_title)
        if producer:
            producer_counts[producer] = count + 1

        if len(results) >= 5:
            break

    return results[:5]


# -----------------------------
# Wine label scan (Gemini Vision + DB match)
# -----------------------------

_GENERIC_VARIETAL_TOKENS = {
    # common varietals / generic wine descriptors that should NOT dominate matching
    "cabernet",
    "sauvignon",
    "merlot",
    "chardonnay",
    "pinot",
    "syrah",
    "shiraz",
    "malbec",
    "riesling",
    "zinfandel",
    "tempranillo",
    "sangiovese",
    "grenache",
    "garnacha",
    "viognier",
    "chenin",
    "gewurztraminer",
    "muscadet",
    "muscato",
    "moscato",
    "rose",
    "rosé",
    "red",
    "white",
    "wine",
    "blend",
    "reserve",
    "réserve",
    "reserva",
    "gran",
    "grand",
    "cru",
    "doc",
    "d'oc",
    "pays",
    "oc",
    "igt",
    "igp",
    "aoc",
    "docg",
    "vin",
    "de",
    "del",
    "della",
    "di",
    "da",
}

_OCR_LEADING_NOISE = {
    "the",
    "le",
    "la",
    "les",
    "el",
    "los",
    "las",
}


def normalize_wine_text(text: str) -> str:
    """
    Normalize OCR / user-facing wine strings to a stable comparable form.

    - lowercase
    - trim whitespace
    - collapse duplicate spaces
    - normalize hyphens/dashes and apostrophes/quotes
    - remove obvious OCR leading noise tokens (e.g. "the", "le") when safe
    - split common joined OCR artifacts (basic)
    """
    if not text:
        return ""

    s = str(text)
    s = s.strip().lower()

    # Normalize unicode quotes/apostrophes
    s = (
        s.replace("’", "'")
        .replace("‘", "'")
        .replace("“", '"')
        .replace("”", '"')
        .replace("`", "'")
    )
    # Normalize dashes to spaces (labels often use hyphen separators)
    s = s.replace("–", "-").replace("—", "-").replace("−", "-")
    s = re.sub(r"[\-_/]+", " ", s)

    # Remove punctuation that tends to be OCR noise (keep alphanumerics and spaces)
    s = re.sub(r"[^a-z0-9\s'&]", " ", s)

    # Fix basic joined artifacts like "fatbastard" -> "fat bastard"
    s = re.sub(r"([a-z])([A-Z])", r"\1 \2", s)
    s = re.sub(r"([a-z])([0-9])", r"\1 \2", s)
    s = re.sub(r"([0-9])([a-z])", r"\1 \2", s)

    # Collapse whitespace
    s = re.sub(r"\s+", " ", s).strip()

    # Remove single leading OCR noise token if present (only at start)
    parts = s.split(" ")
    if len(parts) >= 2 and parts[0] in _OCR_LEADING_NOISE:
        s = " ".join(parts[1:]).strip()

    return s


def _tokenize(text: str) -> List[str]:
    norm = normalize_wine_text(text)
    if not norm:
        return []
    tokens = [t for t in norm.split(" ") if t and len(t) >= 2]
    return tokens


def _sequence_ratio(a: str, b: str) -> float:
    if not a or not b:
        return 0.0
    return difflib.SequenceMatcher(a=a, b=b).ratio()


def _fetch_master_candidates(
    winery_norm: str,
    wine_name_norm: str,
    limit: int = 250,
) -> List[dict]:
    """
    Stage 1: Strict candidate filtering from master_wines.

    - If winery is present, candidates must contain at least one meaningful winery token in systitle.
    - If winery is absent, use wine_name tokens to narrow the set.
    """
    try:
        con = sqlite3.connect(PAIRINGS_DB_PATH)
        con.row_factory = sqlite3.Row
        cur = con.cursor()

        where_clauses: List[str] = []
        params: List[str] = []

        if winery_norm:
            wtoks = [t for t in _tokenize(winery_norm) if t not in _GENERIC_VARIETAL_TOKENS and len(t) >= 3]
            # Require at least one meaningful winery token in the title
            if wtoks:
                like_parts = []
                for t in wtoks[:4]:
                    like_parts.append("LOWER(systitle) LIKE ?")
                    params.append(f"%{t}%")
                where_clauses.append("(" + " OR ".join(like_parts) + ")")
            else:
                # If winery is too generic, do not filter by it (avoid false positives)
                pass
        elif wine_name_norm:
            ntoks = [t for t in _tokenize(wine_name_norm) if len(t) >= 3]
            if ntoks:
                like_parts = []
                for t in ntoks[:4]:
                    like_parts.append("LOWER(systitle) LIKE ?")
                    params.append(f"%{t}%")
                where_clauses.append("(" + " OR ".join(like_parts) + ")")

        where_sql = ""
        if where_clauses:
            where_sql = "WHERE " + " AND ".join(where_clauses)

        cur.execute(
            f"SELECT sku, systitle, ec_final_price, ec_thumbnails, lcbo_tastingnotes FROM master_wines {where_sql} LIMIT ?",
            (*params, int(limit)),
        )
        rows = cur.fetchall()
        return [dict(r) for r in rows]
    except Exception as e:
        print(f"[scan] master_wines candidate fetch failed: {e}")
        return []
    finally:
        try:
            con.close()
        except Exception:
            pass


def _score_candidate(
    *,
    winery_norm: str,
    wine_name_norm: str,
    vintage_norm: str,
    candidate_title: str,
) -> Tuple[float, Dict[str, float]]:
    """
    Stage 2: Weighted scoring. Winery identity dominates; varietal overlap is secondary.
    Returns (total_score, breakdown).
    """
    cand_norm = normalize_wine_text(candidate_title)

    # Winery signals (highest weight)
    winery_ratio = _sequence_ratio(winery_norm, cand_norm) if winery_norm else 0.0
    winery_substring = 1.0 if (winery_norm and winery_norm in cand_norm) else 0.0

    wtoks = set(_tokenize(winery_norm)) if winery_norm else set()
    ctoks = set(_tokenize(cand_norm))
    winery_tok_overlap = (len(wtoks & ctoks) / max(1, len(wtoks))) if wtoks else 0.0

    # Wine-name signals (medium weight)
    name_ratio = _sequence_ratio(wine_name_norm, cand_norm) if wine_name_norm else 0.0
    name_substring = 1.0 if (wine_name_norm and wine_name_norm in cand_norm) else 0.0

    ntoks = set(_tokenize(wine_name_norm)) if wine_name_norm else set()
    # Varietal tokens are down-weighted; compute overlap excluding generic varietal tokens
    ntoks_non_generic = {t for t in ntoks if t not in _GENERIC_VARIETAL_TOKENS}
    tok_overlap_non_generic = (
        (len(ntoks_non_generic & ctoks) / max(1, len(ntoks_non_generic))) if ntoks_non_generic else 0.0
    )

    varietal_only_overlap = (len(ntoks & ctoks) / max(1, len(ntoks))) if ntoks else 0.0

    # Vintage (small weight): only helps slightly if it appears in title
    vintage_match = 1.0 if (vintage_norm and vintage_norm in cand_norm) else 0.0

    breakdown = {
        "winery_substring": winery_substring,
        "winery_ratio": winery_ratio,
        "winery_tok_overlap": winery_tok_overlap,
        "name_substring": name_substring,
        "name_ratio": name_ratio,
        "tok_overlap_non_generic": tok_overlap_non_generic,
        "varietal_only_overlap": varietal_only_overlap,
        "vintage_match": vintage_match,
    }

    total = 0.0
    total += 0.30 * winery_substring
    total += 0.25 * winery_ratio
    total += 0.20 * winery_tok_overlap
    total += 0.10 * name_substring
    total += 0.08 * name_ratio
    total += 0.05 * tok_overlap_non_generic
    total += 0.01 * vintage_match

    # Explicitly prevent varietal-only overlap from carrying the match.
    # If winery is present but has near-zero overlap, drop score hard.
    if winery_norm and (winery_tok_overlap < 0.20 and winery_ratio < 0.35 and winery_substring == 0.0):
        total *= 0.15

    return max(0.0, min(1.0, total)), breakdown


def _match_wine_staged(
    wine_name: str,
    winery: str,
    vintage: str,
) -> Tuple[Optional[dict], float]:
    """
    Stage 1: filter candidates from master_wines (winery-first)
    Stage 2: score candidates
    Stage 3: apply confidence threshold

    Returns (best_master_row_or_none, best_score).
    """
    winery_norm = normalize_wine_text(winery)
    wine_name_norm = normalize_wine_text(wine_name)
    vintage_norm = normalize_wine_text(vintage)

    print(f"[scan] normalized winery={winery_norm!r}")
    print(f"[scan] normalized wine_name={wine_name_norm!r}")
    print(f"[scan] normalized vintage={vintage_norm!r}")

    candidates = _fetch_master_candidates(winery_norm, wine_name_norm, limit=250)

    # Fallback: if no candidates found but we have a name, use FAISS to propose skus,
    # then validate with the same winery-first scoring.
    if not candidates and (wine_name_norm or winery_norm):
        _load_resources()
        query = f"{wine_name} {winery}".strip()
        try:
            docs = vectorstore.similarity_search(query, k=8) if vectorstore is not None else []
            seen = set()
            for d in docs:
                m = d.metadata or {}
                ec_skus = m.get("ec_skus")
                sku = m.get("permanentid") or (
                    ec_skus[0] if isinstance(ec_skus, (list, tuple)) and ec_skus else None
                )
                if not sku:
                    continue
                sku = str(sku)
                if sku in seen:
                    continue
                seen.add(sku)
                row = _get_master_wine_by_sku(sku)
                if row:
                    candidates.append(row)
        except Exception as e:
            print(f"[scan] FAISS fallback search failed: {e}")

    if not candidates:
        return None, 0.0

    best: Optional[dict] = None
    best_score = 0.0

    for c in candidates[:300]:
        title = str(c.get("systitle") or "")
        score, breakdown = _score_candidate(
            winery_norm=winery_norm,
            wine_name_norm=wine_name_norm,
            vintage_norm=vintage_norm,
            candidate_title=title,
        )
        if score > best_score:
            best = c
            best_score = score
        if score >= 0.50:
            print(
                f"[scan] candidate={title!r} score={score:.3f} "
                f"winery_sub={breakdown['winery_substring']:.2f} winery_ratio={breakdown['winery_ratio']:.2f} "
                f"winery_tok={breakdown['winery_tok_overlap']:.2f} name_ratio={breakdown['name_ratio']:.2f} "
                f"tok_non_generic={breakdown['tok_overlap_non_generic']:.2f}"
            )

    # Stage 3: confidence threshold
    # Winery provided => stricter threshold (avoid wrong producer matches)
    threshold = 0.72 if winery_norm else 0.62
    if best is None or best_score < threshold:
        if best is not None:
            print(
                f"[scan] low-confidence match (best_score={best_score:.3f} < {threshold:.2f}) -> matched_db=false"
            )
        return None, best_score

    print(f"[scan] selected candidate={str(best.get('systitle') or '')!r} score={best_score:.3f}")
    return best, best_score


def _scan_wine_label_with_gemini(image_bytes: bytes, mime_type: str) -> dict:
    """Use shared LangChain Gemini (vision) to extract wine name, winery, vintage from label image."""
    try:
        _load_resources()
        if llm is None:
            print("[scan] Gemini LLM not available; cannot analyze image")
            return {}
        prompt = (
            "Identify the wine name, winery, and vintage from this wine bottle label. "
            "Reply with ONLY a JSON object, no other text, using exactly these keys: "
            '"wine_name", "winery", "vintage". Use null for any value you cannot read. '
            "Example: {\"wine_name\": \"Rioja Reserva\", \"winery\": \"La Rioja Alta\", \"vintage\": \"2018\"}"
        )
        print("[scan] Sending image to Gemini")
        b64 = base64.b64encode(image_bytes).decode("ascii")
        data_url = f"data:{mime_type or 'image/jpeg'};base64,{b64}"
        message = HumanMessage(
            content=[
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": data_url}},
            ]
        )
        response = llm.invoke([message])
        if hasattr(response, "content") and response.content:
            text = response.content if isinstance(response.content, str) else str(response.content)
        elif hasattr(response, "text") and response.text:
            text = response.text
        else:
            print("[scan] Gemini returned empty response")
            return {}
        text = text.strip()
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0].strip()
        elif "```" in text:
            text = text.split("```")[1].split("```")[0].strip()
        data = json.loads(text)
        wine_name = (data.get("wine_name") or "").strip() if isinstance(data.get("wine_name"), str) else ""
        winery = (data.get("winery") or "").strip() if isinstance(data.get("winery"), str) else ""
        vintage = (data.get("vintage") or "").strip() if isinstance(data.get("vintage"), str) else ""
        if wine_name or winery or vintage:
            print(f"[scan] Wine identified: wine_name={wine_name!r}, winery={winery!r}, vintage={vintage!r}")
        return {"wine_name": wine_name or None, "winery": winery or None, "vintage": vintage or None}
    except json.JSONDecodeError as e:
        print(f"[scan] Failed to parse Gemini JSON: {e}")
        return {}
    except Exception as e:
        print(f"[scan] Gemini vision error: {e}")
        return {}


@app.post("/scan")
async def scan_wine_label(file: UploadFile = File(...)):
    """Accept a wine label image, analyze with Gemini Vision, optionally match to DB."""
    print("[scan] route hit successfully")
    print(f"[scan] image received filename={file.filename!r} content_type={file.content_type!r}")
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    try:
        image_bytes = await file.read()
    except Exception as e:
        print(f"[scan] Failed to read image: {e}")
        raise HTTPException(status_code=400, detail="Could not read image file")
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Image file is empty")
    mime_type = file.content_type or "image/jpeg"

    extracted = _scan_wine_label_with_gemini(image_bytes, mime_type)
    wine_name = extracted.get("wine_name") or ""
    winery = extracted.get("winery") or ""
    vintage = extracted.get("vintage") or ""

    if not wine_name and not winery:
        print("[scan] No wine identified from label")
        return {"recognized": False}

    master_row, score = _match_wine_staged(wine_name=wine_name, winery=winery, vintage=vintage)
    if master_row:
        sku = master_row.get("sku")
        title = master_row.get("systitle") or (wine_name or "")
        notes = master_row.get("lcbo_tastingnotes") or ""
        thumb = master_row.get("ec_thumbnails")
        raw_price = master_row.get("ec_final_price")
        try:
            price_val = float(raw_price) if raw_price is not None else 0.0
        except (TypeError, ValueError):
            price_val = 0.0

        inventory_url = f"https://www.lcbo.com/en/storeinventory?sku={sku}" if sku else None
        wine_type = normalize_wine_type(
            raw_style=master_row.get("style") or master_row.get("wine_style"),
            title=title,
            notes=notes,
        )
        wine_data = {
            "systitle": title,
            "ec_final_price": price_val,
            "lcbo_tastingnotes": notes,
            "ec_thumbnails": thumb,
            "sku": sku,
            "inventory_url": inventory_url,
            "sommelier_note": "",
            "winery": winery or None,
            "vintage": vintage or None,
            "wine_type": wine_type,
        }
        return {
            "recognized": True,
            "wine_name": wine_name or title,
            "winery": winery or None,
            "vintage": vintage or None,
            "matched_db": True,
            "match_score": round(float(score), 3),
            "wine_data": wine_data,
            "can_contribute": False,
        }

    print("[scan] contribution flow enabled")
    return {
        "recognized": True,
        "wine_name": wine_name,
        "winery": winery or None,
        "vintage": vintage or None,
        "matched_db": False,
        "match_score": round(float(score), 3),
        "wine_data": None,
        "can_contribute": True,
    }


@app.post("/scan/history", response_model=ScanHistoryOut)
async def add_scan_history(
    payload: ScanHistoryCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ScanHistoryOut:
    row = ScanHistory(
        user_id=current_user.id,
        wine_name=payload.wine_name,
        sku=payload.sku,
        image_url=payload.image_url,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@app.get("/scan/history", response_model=List[ScanHistoryOut])
async def get_scan_history(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> List[ScanHistoryOut]:
    rows = (
        db.query(ScanHistory)
        .filter(ScanHistory.user_id == current_user.id)
        .order_by(ScanHistory.scanned_at.desc())
        .limit(10)
        .all()
    )
    return rows


@app.delete("/scan/history/{history_id}")
async def delete_scan_history(
    history_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    row = db.query(ScanHistory).filter(ScanHistory.id == history_id).first()
    if not row:
        raise HTTPException(status_code=404, detail="Scan history entry not found")
    if row.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not allowed to delete this history entry",
        )
    db.delete(row)
    db.commit()
    return {"deleted": True, "id": history_id}


# -----------------------------
# Health
# -----------------------------

@app.get("/health")
async def health():
    return {"status": "ok"}


# -----------------------------
# Discover
# -----------------------------


@app.get("/discover/daily", response_model=List[WineResult])
async def discover_daily_picks():
    wines = discover_daily(limit=3)
    results: List[WineResult] = []
    for w in wines:
        results.append(
            WineResult(
                systitle=w.title,
                ec_final_price=w.price,
                lcbo_tastingnotes=w.notes,
                ec_thumbnails=w.thumb,
                sku=w.sku,
                inventory_url=(
                    f"https://www.lcbo.com/en/storeinventory?sku={w.sku}"
                    if w.sku
                    else None
                ),
                sommelier_note="",
                similarity_reason=w.reason,
                wine_type=w.wine_type,
            )
        )
    return results


@app.get("/discover/collections")
async def discover_collections_list():
    return discover_collections()


@app.get("/discover/collection/{slug}", response_model=List[WineResult])
async def discover_collection_wines(slug: str):
    wines = discover_collection(slug, limit=10)
    results: List[WineResult] = []
    for w in wines:
        results.append(
            WineResult(
                systitle=w.title,
                ec_final_price=w.price,
                lcbo_tastingnotes=w.notes,
                ec_thumbnails=w.thumb,
                sku=w.sku,
                inventory_url=(
                    f"https://www.lcbo.com/en/storeinventory?sku={w.sku}"
                    if w.sku
                    else None
                ),
                sommelier_note="",
                similarity_reason=w.reason,
                wine_type=w.wine_type,
            )
        )
    return results


@app.get("/discover/for-you", response_model=List[WineResult])
async def discover_for_you_picks(
    current_user: Optional[User] = Depends(get_optional_current_user),
    db: Session = Depends(get_db),
    preferred_styles: Optional[str] = None,
    preferred_body: Optional[str] = None,
    preferred_flavors: Optional[str] = None,
    default_budget: Optional[float] = None,
):
    """
    Personalized For You picks using taste profile and/or wine preferences.
    Preferences affect ranking only; no wines are filtered.
    Returns empty list if not authenticated and no preferences provided.
    """
    if current_user is None:
        return []
    wine_prefs: Optional[WinePreferences] = None
    has_prefs = (
        preferred_styles
        or preferred_body
        or preferred_flavors
        or (default_budget and default_budget > 0)
    )
    if has_prefs:
        styles = [s.strip() for s in preferred_styles.split(",")] if preferred_styles else []
        flavors = [f.strip() for f in preferred_flavors.split(",")] if preferred_flavors else []
        wine_prefs = WinePreferences(
            preferred_styles=styles,
            preferred_body=preferred_body or "",
            preferred_flavors=flavors,
            default_budget=default_budget or 0.0,
        )
    wines = discover_for_you(
        db=db,
        user_id=current_user.id,
        limit=6,
        wine_preferences=wine_prefs,
    )
    results: List[WineResult] = []
    for w in wines:
        results.append(
            WineResult(
                systitle=w.title,
                ec_final_price=w.price,
                lcbo_tastingnotes=w.notes,
                ec_thumbnails=w.thumb,
                sku=w.sku,
                inventory_url=(
                    f"https://www.lcbo.com/en/storeinventory?sku={w.sku}"
                    if w.sku
                    else None
                ),
                sommelier_note="",
                similarity_reason=None,
                wine_type=w.wine_type,
            )
        )
    return results


@app.get("/discover/recommended", response_model=List[WineResult])
async def discover_recommended_for_user(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    wines = discover_recommended(db=db, user_id=current_user.id, limit=3)
    results: List[WineResult] = []
    for w in wines:
        results.append(
            WineResult(
                systitle=w.title,
                ec_final_price=w.price,
                lcbo_tastingnotes=w.notes,
                ec_thumbnails=w.thumb,
                sku=w.sku,
                inventory_url=(
                    f"https://www.lcbo.com/en/storeinventory?sku={w.sku}"
                    if w.sku
                    else None
                ),
                sommelier_note="",
                similarity_reason=w.reason,
                wine_type=w.wine_type,
            )
        )
    return results


@app.get("/discover/budget", response_model=List[WineResult])
async def discover_budget_picks(max_price: float = 20.0):
    wines = discover_budget(max_price=max_price, limit=3)
    results: List[WineResult] = []
    for w in wines:
        results.append(
            WineResult(
                systitle=w.title,
                ec_final_price=w.price,
                lcbo_tastingnotes=w.notes,
                ec_thumbnails=w.thumb,
                sku=w.sku,
                inventory_url=(
                    f"https://www.lcbo.com/en/storeinventory?sku={w.sku}"
                    if w.sku
                    else None
                ),
                sommelier_note="",
                similarity_reason=w.reason,
                wine_type=w.wine_type,
            )
        )
    return results
