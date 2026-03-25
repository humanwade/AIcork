# AWS Backend Deployment (FastAPI + PostgreSQL)

The application database (`APP_DATABASE_URL`) holds **both** transactional data
(users, cellar, scan history) and the **wine catalog** (`master_wines`).

## 1) Environment variables

Set these in AWS Secrets Manager / ECS task definition:

- `APP_DATABASE_URL=postgresql+psycopg://<user>:<password>@<rds-endpoint>:5432/<db>`
- `SECRET_KEY=<long-random-secret>`
- `SMTP_HOST`, `SMTP_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM`

Optional:

- `GOOGLE_API_KEY` (recommendations / similar wines)

## 2) Build and run container

From repo root:

```bash
docker build -f backend/Dockerfile -t corkey-backend:latest .
```

Local stack:

```bash
docker compose up --build
```

Mount or bake `data/wine_faiss_index` into the container for `/recommend` and
`/wine/{sku}/similar` (see `wine_index_builder.py`).

## 3) Migrate legacy SQLite data to PostgreSQL

Copies transactional tables **and** `master_wines` from a source SQLite file
(often `data/pairings.db`) into PostgreSQL. **Truncates** the listed target
tables first.

```bash
export APP_DATABASE_URL='postgresql+psycopg://...'
export SOURCE_SQLITE_PATH='./data/pairings.db'
python backend/scripts/migrate_sqlite_to_postgres.py
```

## 4) Load catalog from JSON (optional)

If you rebuild the DB from the LCBO master JSON instead of SQLite:

```bash
export APP_DATABASE_URL='postgresql+psycopg://...'
python backend/import_master_wines.py
```

## 5) Notes

- Discover and scan matching read `master_wines` through SQLAlchemy on
  `APP_DATABASE_URL`.
- Recommendation still uses the on-disk FAISS index; rebuild the index after
  major catalog changes if embeddings must stay aligned.
