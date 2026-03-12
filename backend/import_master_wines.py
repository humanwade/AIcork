import json
import sqlite3
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"

MASTER_JSON_PATH = Path(
    str(
        Path(
            # keep as a Path literal for easy override if needed
            DATA_DIR / "9480_wine_final_master.json"
        )
    )
)

PAIRINGS_DB_PATH = DATA_DIR / "pairings.db"


def _derive_sku(record: Dict[str, Any]) -> Optional[str]:
    """
    Derive a stable SKU identifier for master_wines.

    The current master JSON does not contain a 'sku' field, but it includes:
    - permanentid (string/int)
    - ec_skus (list)
    We normalize to a string SKU.
    """
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


def _sqlite_value(v: Any) -> Any:
    if v is None:
        return None
    if isinstance(v, (str, int, float)):
        return v
    if isinstance(v, bool):
        return int(v)
    # lists/dicts/other -> JSON string
    return json.dumps(v, ensure_ascii=False)


def _create_master_wines_table(con: sqlite3.Connection, keys: Sequence[str]) -> None:
    cols: List[str] = ['"sku" TEXT UNIQUE']
    for k in keys:
        if k == "sku":
            continue
        cols.append(f'"{k}" TEXT')
    col_sql = ",\n    ".join(cols)
    con.execute(
        f"""
        CREATE TABLE IF NOT EXISTS master_wines (
            {col_sql}
        )
        """
    )


def _upsert_records(
    con: sqlite3.Connection,
    records: Iterable[Dict[str, Any]],
    keys: Sequence[str],
) -> Tuple[int, int]:
    """
    Insert records using INSERT OR IGNORE (sku UNIQUE).
    Returns (inserted_or_kept, skipped_no_sku).
    """
    cols = ["sku"] + [k for k in keys if k != "sku"]
    col_sql = ", ".join([f'"{c}"' for c in cols])
    placeholders = ", ".join(["?"] * len(cols))
    sql = f"INSERT OR IGNORE INTO master_wines ({col_sql}) VALUES ({placeholders})"

    skipped_no_sku = 0
    batch: List[Tuple[Any, ...]] = []
    total_written = 0

    for r in records:
        sku = _derive_sku(r)
        if not sku:
            skipped_no_sku += 1
            continue
        row = [_sqlite_value(sku)]
        for k in cols[1:]:
            row.append(_sqlite_value(r.get(k)))
        batch.append(tuple(row))
        if len(batch) >= 500:
            con.executemany(sql, batch)
            total_written += len(batch)
            batch.clear()

    if batch:
        con.executemany(sql, batch)
        total_written += len(batch)

    return total_written, skipped_no_sku


def main() -> None:
    if not MASTER_JSON_PATH.exists():
        raise SystemExit(f"Master JSON not found: {MASTER_JSON_PATH}")
    if not PAIRINGS_DB_PATH.exists():
        raise SystemExit(f"Database not found: {PAIRINGS_DB_PATH}")

    records: List[Dict[str, Any]] = json.loads(MASTER_JSON_PATH.read_text(encoding="utf-8"))
    if not isinstance(records, list) or (records and not isinstance(records[0], dict)):
        raise SystemExit("Unexpected master JSON format: expected a list of objects")

    keys_set = set()
    for r in records:
        keys_set.update(r.keys())
    # Ensure deterministic column order
    keys = sorted(keys_set)

    con = sqlite3.connect(str(PAIRINGS_DB_PATH))
    try:
        con.execute("PRAGMA journal_mode=WAL")
        con.execute("PRAGMA synchronous=NORMAL")
        con.execute("PRAGMA temp_store=MEMORY")

        _create_master_wines_table(con, keys)
        written, skipped_no_sku = _upsert_records(con, records, keys)
        con.commit()

        cur = con.cursor()
        cur.execute("SELECT COUNT(*) FROM master_wines")
        (count,) = cur.fetchone()

        print(f"master_json_records={len(records)}")
        print(f"unique_json_keys={len(keys)}")
        print(f"batch_rows_processed={written} (INSERT OR IGNORE)")
        print(f"skipped_no_sku={skipped_no_sku}")
        print(f"master_wines_row_count={count}")
    finally:
        con.close()


if __name__ == '__main__':
    main()
