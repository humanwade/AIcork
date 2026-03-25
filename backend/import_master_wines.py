import json
import sys
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple


BACKEND_DIR = Path(__file__).resolve().parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from catalog_utils import master_wine_from_flat_row  # noqa: E402
from database import Base, SessionLocal, engine  # noqa: E402
from models import MasterWine  # noqa: E402


PROJECT_ROOT = BACKEND_DIR.parent
DATA_DIR = PROJECT_ROOT / "data"

MASTER_JSON_PATH = Path(
    str(
        Path(
            DATA_DIR / "9480_wine_final_master.json"
        )
    )
)


def _derive_sku(record: Dict[str, Any]) -> Optional[str]:
    sku = record.get("sku")
    if isinstance(sku, str) and sku.strip():
        return sku.strip()
    if isinstance(sku, int):
        return str(sku)

    permanentid = record.get("permanentid")
    if isinstance(permanentid, str) and permanentid.strip():
        return permanentid.strip()
    if isinstance(permanentid, int):
        return str(permanentid)

    ec_skus = record.get("ec_skus")
    if isinstance(ec_skus, (list, tuple)) and ec_skus:
        first = ec_skus[0]
        if isinstance(first, str) and first.strip():
            return first.strip()
        if isinstance(first, int):
            return str(first)

    return None


def _upsert_records(records: Iterable[Dict[str, Any]]) -> Tuple[int, int]:
    """
    Upsert into master_wines on the application database.
    Returns (rows_merged, skipped_no_sku).
    """

    skipped_no_sku = 0
    total_written = 0
    db = SessionLocal()
    try:
        for r in records:
            sku = _derive_sku(r)
            if not sku:
                skipped_no_sku += 1
                continue
            merged: Dict[str, Any] = dict(r)
            merged["sku"] = sku
            mw = master_wine_from_flat_row(merged)
            if mw is None:
                skipped_no_sku += 1
                continue
            db.merge(mw)
            total_written += 1
            if total_written % 500 == 0:
                db.commit()
        db.commit()
    finally:
        db.close()

    return total_written, skipped_no_sku


def main() -> None:
    if not MASTER_JSON_PATH.exists():
        raise SystemExit(f"Master JSON not found: {MASTER_JSON_PATH}")

    records: List[Dict[str, Any]] = json.loads(MASTER_JSON_PATH.read_text(encoding="utf-8"))
    if not isinstance(records, list) or (records and not isinstance(records[0], dict)):
        raise SystemExit("Unexpected master JSON format: expected a list of objects")

    keys_set = set()
    for r in records:
        keys_set.update(r.keys())
    keys = sorted(keys_set)

    Base.metadata.create_all(bind=engine)

    written, skipped_no_sku = _upsert_records(records)

    db = SessionLocal()
    try:
        count = db.query(MasterWine).count()
    finally:
        db.close()

    print(f"master_json_records={len(records)}")
    print(f"unique_json_keys={len(keys)}")
    print(f"batch_rows_processed={written} (merge by sku)")
    print(f"skipped_no_sku={skipped_no_sku}")
    print(f"master_wines_row_count={count}")


if __name__ == "__main__":
    main()
