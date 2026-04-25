from __future__ import annotations

import hashlib
import json
import sqlite3
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import List, Optional


BASE_DIR = Path(__file__).resolve().parents[1]
CACHE_DIR = BASE_DIR / "cache"
CACHE_PATH = CACHE_DIR / "recommendation_cache.sqlite3"
TTL_DAYS = 7


def _conn() -> sqlite3.Connection:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(str(CACHE_PATH))
    con.execute("PRAGMA journal_mode=WAL")
    con.execute("PRAGMA synchronous=NORMAL")
    con.execute(
        """
        CREATE TABLE IF NOT EXISTS sommelier_note_cache (
            cache_key TEXT PRIMARY KEY,
            normalized_query TEXT NOT NULL,
            sku_list TEXT NOT NULL,
            top_k INTEGER NOT NULL,
            max_budget REAL NOT NULL,
            preferences_hash TEXT,
            response_notes_json TEXT NOT NULL,
            created_at TEXT NOT NULL,
            expires_at TEXT NOT NULL,
            hit_count INTEGER NOT NULL DEFAULT 0
        )
        """
    )
    return con


def normalize_query(query: str) -> str:
    return " ".join((query or "").strip().lower().split())


def hash_preferences(preferences_payload: Optional[dict]) -> Optional[str]:
    if not preferences_payload:
        return None
    payload = json.dumps(preferences_payload, ensure_ascii=False, sort_keys=True)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def build_cache_key(
    *,
    normalized_query: str,
    sku_list: List[str],
    top_k: int,
    max_budget: float,
    preferences_hash: Optional[str],
) -> str:
    key_input = {
        "q": normalized_query,
        "skus": sku_list,
        "top_k": int(top_k),
        "max_budget": float(max_budget),
        "prefs": preferences_hash,
    }
    raw = json.dumps(key_input, ensure_ascii=False, sort_keys=True)
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def get_cached_notes(
    *,
    cache_key: str,
) -> Optional[List[str]]:
    now = datetime.now(timezone.utc).isoformat()
    with _conn() as con:
        cur = con.execute(
            """
            SELECT response_notes_json
            FROM sommelier_note_cache
            WHERE cache_key = ? AND expires_at > ?
            LIMIT 1
            """,
            (cache_key, now),
        )
        row = cur.fetchone()
        if row is None:
            print("[recommend] sommelier cache miss")
            return None
        con.execute(
            """
            UPDATE sommelier_note_cache
            SET hit_count = hit_count + 1
            WHERE cache_key = ?
            """,
            (cache_key,),
        )
        print("[recommend] sommelier cache hit")
        try:
            notes = json.loads(row[0])
            if isinstance(notes, list):
                return [str(n) for n in notes]
        except Exception:
            return None
    return None


def save_cached_notes(
    *,
    cache_key: str,
    normalized_query: str,
    sku_list: List[str],
    top_k: int,
    max_budget: float,
    preferences_hash: Optional[str],
    response_notes: List[str],
) -> None:
    now = datetime.now(timezone.utc)
    expires = now + timedelta(days=TTL_DAYS)
    with _conn() as con:
        con.execute(
            """
            INSERT OR REPLACE INTO sommelier_note_cache (
                cache_key,
                normalized_query,
                sku_list,
                top_k,
                max_budget,
                preferences_hash,
                response_notes_json,
                created_at,
                expires_at,
                hit_count
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, COALESCE(
                (SELECT hit_count FROM sommelier_note_cache WHERE cache_key = ?), 0
            ))
            """,
            (
                cache_key,
                normalized_query,
                json.dumps(sku_list, ensure_ascii=False),
                int(top_k),
                float(max_budget),
                preferences_hash,
                json.dumps(response_notes, ensure_ascii=False),
                now.isoformat(),
                expires.isoformat(),
                cache_key,
            ),
        )
    print("[recommend] sommelier cache saved")
